#!/bin/bash
# Script de sauvegarde automatique Odoo
set -e

echo "🚀 Démarrage du service de backup automatique..."
echo "Configuration:"
echo "  - Base de données: ${DB_NAME:-odoo}"
echo "  - Utilisateur: ${DB_USER:-odoo}"
echo "  - Hôte: db"
echo "  - Intervalle: 24h"
echo "  - Rétention: 7 jours"
if [ -n "$RCLONE_DROPBOX_TOKEN" ]; then
    echo "  - Stockage distant: Dropbox (configuré)"
else
    echo "  - Stockage distant: Non configuré"
fi
echo ""

# Installer les dépendances
echo "📦 Installation des dépendances..."
apt-get update > /dev/null 2>&1
apt-get install -y rclone cron > /dev/null 2>&1
echo "✅ Dépendances installées"
echo ""

# Configurer rclone si token Dropbox fourni
if [ -n "$RCLONE_DROPBOX_TOKEN" ]; then
    echo "🔧 Configuration du stockage distant Dropbox..."
    mkdir -p ~/.config/rclone
    cat > ~/.config/rclone/rclone.conf <<EOF
[remote]
type = dropbox
token = {"access_token":"$RCLONE_DROPBOX_TOKEN","token_type":"bearer","expiry":"0001-01-01T00:00:00Z"}
EOF
    echo "✅ Stockage distant configuré"
    echo ""
fi

# Boucle de backup
while true; do
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="/backups/odoo_db_${TIMESTAMP}.dump"
    
    echo "======================================"
    echo "🔄 Début du backup à $(date)"
    echo "======================================"
    
    # Backup de la base de données
    echo "📊 Sauvegarde de la base de données PostgreSQL..."
    if pg_dump -h db -U "${DB_USER:-odoo}" -d "${DB_NAME:-odoo}" -F c -b -v -f "$BACKUP_FILE" 2>&1 | tail -n 5; then
        BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        echo "✅ Base de données sauvegardée avec succès ($BACKUP_SIZE)"
    else
        echo "❌ Échec de la sauvegarde de la base de données"
    fi
    
    # Synchronisation distante si configurée
    if [ -n "$RCLONE_DROPBOX_TOKEN" ]; then
        echo ""
        echo "☁️  Synchronisation vers Dropbox..."
        
        echo "  → Synchronisation des fichiers Odoo..."
        if rclone copy /data/odoo_filestore remote:openeducat_backups/files --progress 2>&1 | tail -n 3; then
            echo "  ✅ Fichiers Odoo synchronisés"
        else
            echo "  ❌ Échec de la synchronisation des fichiers"
        fi
        
        echo "  → Synchronisation des dumps SQL..."
        if rclone copy /backups remote:openeducat_backups/sql --progress 2>&1 | tail -n 3; then
            echo "  ✅ Dumps SQL synchronisés"
        else
            echo "  ❌ Échec de la synchronisation des dumps SQL"
        fi
    fi
    
    # Nettoyage des anciens backups
    echo ""
    echo "🧹 Nettoyage des backups de plus de 7 jours..."
    OLD_BACKUPS=$(find /backups -name '*.dump' -mtime +7 2>/dev/null)
    if [ -n "$OLD_BACKUPS" ]; then
        echo "$OLD_BACKUPS" | while read -r file; do
            rm -f "$file"
            echo "  🗑️  Supprimé: $(basename "$file")"
        done
    else
        echo "  ℹ️  Aucun backup ancien à nettoyer"
    fi
    
    echo ""
    echo "======================================"
    echo "✅ Backup terminé à $(date)"
    echo "======================================"
    echo ""
    echo "⏳ Prochaine sauvegarde dans 24 heures..."
    echo ""
    
    sleep 86400  # 24 heures
done
