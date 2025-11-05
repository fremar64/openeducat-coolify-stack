#!/bin/bash
# Script de test de restauration de backup Odoo
# Usage: ./test_restore.sh [chemin_vers_backup.dump]

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "======================================"
echo "🔄 TEST DE RESTAURATION BACKUP ODOO"
echo "======================================"
echo ""

# Variables
DB_NAME="${DB_NAME:-odoo}"
DB_USER="${DB_USER:-odoo}"
DB_HOST="${DB_HOST:-db}"
TEST_DB_NAME="odoo_test_$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="${1:-}"

# Vérifier qu'un fichier backup est fourni
if [ -z "$BACKUP_FILE" ]; then
    echo -e "${YELLOW}📁 Backups disponibles:${NC}"
    if [ -d "/backups" ]; then
        ls -lh /backups/*.dump 2>/dev/null | tail -n 10 || echo "  ℹ️  Aucun backup trouvé dans /backups/"
    fi
    echo ""
    echo -e "${RED}❌ Usage: $0 <chemin_vers_backup.dump>${NC}"
    echo ""
    echo "Exemple:"
    echo "  $0 /backups/odoo_db_20251105_025254.dump"
    exit 1
fi

# Vérifier que le fichier existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}❌ Erreur: Le fichier '$BACKUP_FILE' n'existe pas${NC}"
    exit 1
fi

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo -e "${BLUE}📦 Backup sélectionné:${NC}"
echo "  Fichier: $BACKUP_FILE"
echo "  Taille: $BACKUP_SIZE"
echo ""

# Vérifier la connexion PostgreSQL
echo -e "${BLUE}🔌 Vérification de la connexion PostgreSQL...${NC}"
if ! pg_isready -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" &> /dev/null; then
    echo -e "${RED}❌ Impossible de se connecter à PostgreSQL${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Connexion PostgreSQL OK${NC}"
echo ""

# Créer la base de données de test
echo -e "${BLUE}🗄️  Création de la base de test: $TEST_DB_NAME${NC}"
if psql -h "$DB_HOST" -U "$DB_USER" -lqt | cut -d \| -f 1 | grep -qw "$TEST_DB_NAME"; then
    echo -e "${YELLOW}⚠️  La base $TEST_DB_NAME existe déjà, suppression...${NC}"
    psql -h "$DB_HOST" -U "$DB_USER" -c "DROP DATABASE \"$TEST_DB_NAME\";" 2>/dev/null || true
fi

psql -h "$DB_HOST" -U "$DB_USER" -c "CREATE DATABASE \"$TEST_DB_NAME\" OWNER $DB_USER;"
echo -e "${GREEN}✅ Base de test créée${NC}"
echo ""

# Restaurer le backup
echo -e "${BLUE}📥 Restauration du backup (cela peut prendre quelques minutes)...${NC}"
echo ""

START_TIME=$(date +%s)

if pg_restore -h "$DB_HOST" -U "$DB_USER" -d "$TEST_DB_NAME" -v "$BACKUP_FILE" 2>&1 | tail -n 20; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    echo ""
    echo -e "${GREEN}✅ Restauration terminée en ${DURATION}s${NC}"
else
    echo ""
    echo -e "${RED}❌ Erreur lors de la restauration${NC}"
    echo -e "${YELLOW}ℹ️  Nettoyage de la base de test...${NC}"
    psql -h "$DB_HOST" -U "$DB_USER" -c "DROP DATABASE \"$TEST_DB_NAME\";" 2>/dev/null || true
    exit 1
fi
echo ""

# Vérifier l'intégrité de la restauration
echo -e "${BLUE}🔍 Vérification de l'intégrité...${NC}"
echo ""

# Compter les tables
TABLE_COUNT=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$TEST_DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';" 2>/dev/null | tr -d ' ')
echo "  📊 Nombre de tables: $TABLE_COUNT"

# Vérifier quelques tables critiques Odoo
CRITICAL_TABLES=("res_users" "res_partner" "ir_module_module" "ir_model" "res_company")
ALL_OK=true

for table in "${CRITICAL_TABLES[@]}"; do
    if psql -h "$DB_HOST" -U "$DB_USER" -d "$TEST_DB_NAME" -t -c "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = '$table');" 2>/dev/null | grep -q 't'; then
        ROW_COUNT=$(psql -h "$DB_HOST" -U "$DB_USER" -d "$TEST_DB_NAME" -t -c "SELECT COUNT(*) FROM $table;" 2>/dev/null | tr -d ' ')
        echo -e "  ${GREEN}✅${NC} Table '$table': $ROW_COUNT lignes"
    else
        echo -e "  ${RED}❌${NC} Table '$table': MANQUANTE"
        ALL_OK=false
    fi
done
echo ""

# Vérifier les modules installés
echo -e "${BLUE}📦 Modules installés dans la base restaurée:${NC}"
psql -h "$DB_HOST" -U "$DB_USER" -d "$TEST_DB_NAME" -c "SELECT name, state FROM ir_module_module WHERE state IN ('installed', 'to upgrade', 'to remove') ORDER BY name LIMIT 20;" 2>/dev/null | head -n 25
echo ""

# Vérifier les utilisateurs
echo -e "${BLUE}👥 Utilisateurs dans la base restaurée:${NC}"
psql -h "$DB_HOST" -U "$DB_USER" -d "$TEST_DB_NAME" -c "SELECT login, active FROM res_users ORDER BY id LIMIT 10;" 2>/dev/null | head -n 15
echo ""

# Résumé
echo "======================================"
if [ "$ALL_OK" = true ] && [ "$TABLE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✅ TEST DE RESTAURATION RÉUSSI !${NC}"
    echo ""
    echo "La base de test '$TEST_DB_NAME' contient:"
    echo "  - $TABLE_COUNT tables"
    echo "  - Toutes les tables critiques sont présentes"
    echo "  - Les données ont été restaurées"
else
    echo -e "${RED}⚠️  TEST DE RESTAURATION INCOMPLET${NC}"
    echo ""
    echo "Certaines vérifications ont échoué."
fi
echo "======================================"
echo ""

# Proposer de nettoyer ou garder
echo -e "${YELLOW}🧹 Que souhaitez-vous faire avec la base de test?${NC}"
echo "  1) La SUPPRIMER maintenant (recommandé)"
echo "  2) La GARDER pour inspection manuelle"
echo ""
read -p "Votre choix (1/2): " CHOICE

if [ "$CHOICE" = "1" ]; then
    echo ""
    echo -e "${BLUE}🗑️  Suppression de la base de test...${NC}"
    psql -h "$DB_HOST" -U "$DB_USER" -c "DROP DATABASE \"$TEST_DB_NAME\";" 2>/dev/null
    echo -e "${GREEN}✅ Base de test supprimée${NC}"
else
    echo ""
    echo -e "${YELLOW}ℹ️  Base de test conservée: $TEST_DB_NAME${NC}"
    echo ""
    echo "Pour la supprimer plus tard:"
    echo "  psql -h $DB_HOST -U $DB_USER -c \"DROP DATABASE $TEST_DB_NAME;\""
fi

echo ""
echo "======================================"
echo -e "${GREEN}🎉 TEST TERMINÉ${NC}"
echo "======================================"
