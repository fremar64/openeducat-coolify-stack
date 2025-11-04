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

echo "   Variables: ADMIN_EMAIL=${ADMIN_EMAIL:-non défini}, ODOO_ADMIN_PASSWORD=*****, DB_NAME=${DB_NAME:-odoo}"

# Créer un script Python temporaire
cat > /tmp/align_admin.py <<'PYSCRIPT'
import sys
import os

try:
    import odoo
    from odoo import api, SUPERUSER_ID
    from odoo.modules.registry import Registry
    
    DB_HOST = os.environ.get('DB_HOST', 'db')
    DB_PORT = os.environ.get('DB_PORT', '5432')
    DB_USER = os.environ.get('DB_USER', 'odoo')
    DB_PASSWORD = os.environ.get('DB_PASSWORD', os.environ.get('POSTGRES_PASSWORD'))
    DB_NAME = os.environ.get('DB_NAME', 'odoo')
    
    email = os.environ.get('ADMIN_EMAIL')
    pwd = os.environ.get('ODOO_ADMIN_PASSWORD')
    
    if not email and not pwd:
        print("⚠️  Aucune valeur à aligner", file=sys.stderr)
        sys.exit(0)
    
    # Configurer l'accès DB pour Odoo
    odoo.tools.config['db_host'] = DB_HOST
    odoo.tools.config['db_port'] = DB_PORT
    odoo.tools.config['db_user'] = DB_USER
    odoo.tools.config['db_password'] = DB_PASSWORD
    
    print(f"   Connexion à {DB_NAME}@{DB_HOST}:{DB_PORT}...", file=sys.stderr)
    
    # Obtenir le registre et créer un environnement (Odoo 18)
    registry = Registry(DB_NAME)
    with registry.cursor() as cr:
        env = api.Environment(cr, SUPERUSER_ID, {})
        admin = env.ref('base.user_admin')
        
        vals = {}
        if email:
            vals['email'] = email
            vals['login'] = email
            print(f"   → Login/Email: {email}", file=sys.stderr)
        if vals:
            admin.write(vals)
        
        if pwd:
            admin.write({'password': pwd})
            print(f"   → Mot de passe: *****", file=sys.stderr)
        
        cr.commit()
    
    print("✅ Identifiants admin alignés avec succès", file=sys.stderr)
    sys.exit(0)

except Exception as e:
    print(f"❌ Erreur lors de l'alignement: {e}", file=sys.stderr)
    import traceback
    traceback.print_exc(file=sys.stderr)
    sys.exit(1)
PYSCRIPT

# Exécuter le script Python
if python3 /tmp/align_admin.py; then
  echo "✅ Alignement terminé"
  rm -f /tmp/align_admin.py
else
  echo "❌ Échec de l'alignement (voir logs ci-dessus)"
  rm -f /tmp/align_admin.py
  exit 1
fi
