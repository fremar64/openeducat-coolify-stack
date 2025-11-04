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

read -r -d '' PYCODE <<'PY'
import os
import odoo
import odoo.modules.registry
from odoo import api

DB_HOST = os.environ.get('DB_HOST', 'db')
DB_PORT = os.environ.get('DB_PORT', '5432')
DB_USER = os.environ.get('DB_USER', 'odoo')
DB_PASSWORD = os.environ.get('DB_PASSWORD', os.environ.get('POSTGRES_PASSWORD'))
DB_NAME = os.environ.get('DB_NAME', 'odoo')

email = os.environ.get('ADMIN_EMAIL')
pwd = os.environ.get('ODOO_ADMIN_PASSWORD')

# Configurer l'accès DB pour Odoo
odoo.tools.config['db_host'] = DB_HOST
odoo.tools.config['db_port'] = DB_PORT
odoo.tools.config['db_user'] = DB_USER
odoo.tools.config['db_password'] = DB_PASSWORD

with api.Environment.manage():
    registry = odoo.modules.registry.Registry(DB_NAME)
    with registry.cursor() as cr:
        env = api.Environment(cr, odoo.SUPERUSER_ID, {})
        admin = env.ref('base.user_admin')
        vals = {}
        if email:
            vals['email'] = email
            vals['login'] = email
        if vals:
            admin.write(vals)
        if pwd:
            admin.write({'password': pwd})
        cr.commit()
print("✅ Identifiants admin alignés")
PY

python3 - <<PYTHON
${PYCODE}
PYTHON

echo "✅ Alignement terminé"
