#!/usr/bin/env bash

# Script d'initialisation pour OpenEduCat
# Ce script installe automatiquement les modules OpenEduCat

set -euo pipefail

echo "🚀 Initialisation d'OpenEduCat..."

# Attendre que la base de données soit prête
echo "⏳ Attente de la base de données..."
while ! pg_isready -h ${DB_HOST:-db} -p ${DB_PORT:-5432} -U ${DB_USER:-odoo} -d ${DB_NAME:-odoo}; do
    sleep 2
done

echo "✅ Base de données prête"

# Créer la base de données si elle n'existe pas
echo "🔧 Initialisation de la base de données..."
odoo \
    -c /etc/odoo/odoo.conf \
    --db_host ${DB_HOST:-db} \
    --db_port ${DB_PORT:-5432} \
    --db_user ${DB_USER:-odoo} \
    --db_password ${DB_PASSWORD:-$POSTGRES_PASSWORD} \
    -i base -d ${DB_NAME:-odoo} --stop-after-init --no-http

# Installer les modules OpenEduCat de base
echo "📚 Installation des modules OpenEduCat..."
odoo \
    -c /etc/odoo/odoo.conf \
    --db_host ${DB_HOST:-db} \
    --db_port ${DB_PORT:-5432} \
    --db_user ${DB_USER:-odoo} \
    --db_password ${DB_PASSWORD:-$POSTGRES_PASSWORD} \
    -i openeducat_core,openeducat_core_enterprise,openeducat_admission,openeducat_student -d ${DB_NAME:-odoo} --stop-after-init --no-http

echo "✅ OpenEduCat initialisé avec succès!"
echo "🌐 Votre instance OpenEduCat est prête"
echo "👤 Utilisateur admin: admin"
echo "� Mot de passe admin: caché dans les logs (voir variable d'environnement ODOO_ADMIN_PASSWORD)"