#!/bin/bash
# Script de diagnostic du système de backup

echo "======================================"
echo "🔍 DIAGNOSTIC SYSTÈME DE BACKUP"
echo "======================================"
echo ""

echo "📋 Variables d'environnement:"
echo "  - DB_NAME: ${DB_NAME:-odoo}"
echo "  - DB_USER: ${DB_USER:-odoo}"
echo "  - PGPASSWORD: $([ -n "$PGPASSWORD" ] && echo "✅ Défini" || echo "❌ Non défini")"
echo "  - RCLONE_DROPBOX_TOKEN: $([ -n "$RCLONE_DROPBOX_TOKEN" ] && echo "✅ Configuré" || echo "ℹ️  Non configuré")"
echo ""

echo "🔧 Outils disponibles:"
if command -v pg_dump &> /dev/null; then
    PG_VERSION=$(pg_dump --version | head -n1)
    echo "  ✅ pg_dump: $PG_VERSION"
else
    echo "  ❌ pg_dump: NON DISPONIBLE"
fi

if command -v rclone &> /dev/null; then
    RCLONE_VERSION=$(rclone --version | head -n1)
    echo "  ✅ rclone: $RCLONE_VERSION"
else
    echo "  ❌ rclone: NON DISPONIBLE"
fi
echo ""

echo "🔌 Connectivité PostgreSQL:"
if pg_isready -h db -U "${DB_USER:-odoo}" -d "${DB_NAME:-odoo}" &> /dev/null; then
    echo "  ✅ Base de données accessible (db:5432)"
else
    echo "  ❌ Impossible de se connecter à la base de données"
fi
echo ""

echo "📁 Répertoire de backup:"
if [ -d "/backups" ]; then
    echo "  ✅ Répertoire /backups existe"
    echo "  📊 Espace disque:"
    df -h /backups | tail -n1 | awk '{print "     Disponible: " $4 " / " $2 " (" $5 " utilisé)"}'
    
    echo "  📦 Backups existants:"
    BACKUP_COUNT=$(find /backups -name "*.dump" 2>/dev/null | wc -l)
    if [ "$BACKUP_COUNT" -gt 0 ]; then
        echo "     Nombre de backups: $BACKUP_COUNT"
        echo "     Derniers backups:"
        find /backups -name "*.dump" -type f -printf "       %TY-%Tm-%Td %TH:%TM - %f (%s bytes)\n" 2>/dev/null | sort -r | head -n 5
    else
        echo "     ⚠️  Aucun backup trouvé"
    fi
else
    echo "  ❌ Répertoire /backups n'existe pas"
fi
echo ""

echo "📊 Permissions:"
echo "  Utilisateur courant: $(whoami) (UID=$(id -u), GID=$(id -g))"
if [ -w "/backups" ]; then
    echo "  ✅ Écriture autorisée dans /backups"
else
    echo "  ❌ Écriture interdite dans /backups"
fi
echo ""

echo "🧪 Test de backup (simulation):"
TEST_FILE="/backups/test_$(date +%Y%m%d_%H%M%S).txt"
if echo "Test backup" > "$TEST_FILE" 2>/dev/null; then
    echo "  ✅ Création de fichier test réussie"
    rm -f "$TEST_FILE"
    echo "  ✅ Suppression de fichier test réussie"
else
    echo "  ❌ Impossible de créer un fichier de test"
fi
echo ""

echo "======================================"
echo "✅ DIAGNOSTIC TERMINÉ"
echo "======================================"
