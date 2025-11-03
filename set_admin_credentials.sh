#!/usr/bin/env bash
set -euo pipefail

echo "🔐 Alignement des identifiants admin Odoo..."

# Attendre que la base de données soit prête
while ! pg_isready -h ${DB_HOST:-db} -p ${DB_PORT:-5432} -U ${DB_USER:-odoo} -d ${DB_NAME:-odoo} >/dev/null 2>&1; do
  sleep 2
done

if [ -z "${ODOO_ADMIN_PASSWORD:-}" ] && [ -z "${ADMIN_EMAIL:-}" ]; then
  echo "ℹ️  Aucune variable ODOO_ADMIN_PASSWORD/ADMIN_EMAIL fournie, on saute."
  exit 0
fi

# Construire le script Python à exécuter dans odoo shell
read -r -d '' PYCODE <<'PY'
import os
from odoo import tools

email = os.environ.get('ADMIN_EMAIL')
pwd = os.environ.get('ODOO_ADMIN_PASSWORD')

admin = env.ref('base.user_admin')
vals = {}
if email:
    vals['email'] = email
    # Utiliser l'email comme identifiant de connexion pour correspondre à l'usage
    vals['login'] = email
if vals:
    admin.write(vals)
if pwd:
    admin.write({'password': pwd})
print("✅ Identifiants admin alignés")
PY

# Exécuter le script via odoo shell (non interactif)
odoo \
  -c /etc/odoo/odoo.conf \
  --db_host ${DB_HOST:-db} \
  --db_port ${DB_PORT:-5432} \
  --db_user ${DB_USER:-odoo} \
  --db_password ${DB_PASSWORD:-$POSTGRES_PASSWORD} \
  -d ${DB_NAME:-odoo} shell <<<"${PYCODE}"

echo "✅ Alignement terminé"
