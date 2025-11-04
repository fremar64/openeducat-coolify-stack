#!/usr/bin/env bash
# Script de diagnostic pour vérifier la présence des modules OpenEduCat

echo "🔍 Diagnostic des modules OpenEduCat"
echo "===================================="
echo ""

echo "1. Contenu de /mnt/extra-addons:"
ls -la /mnt/extra-addons/ 2>/dev/null || echo "❌ Répertoire /mnt/extra-addons introuvable"
echo ""

echo "2. Modules openeducat présents:"
find /mnt/extra-addons -name "__manifest__.py" -o -name "__openerp__.py" | grep -i openeducat || echo "⚠️  Aucun module openeducat trouvé"
echo ""

echo "3. Chemins addons dans odoo.conf:"
grep "addons_path" /etc/odoo/odoo.conf 2>/dev/null || echo "❌ odoo.conf introuvable"
echo ""

echo "4. Test d'import Python:"
python3 -c "
import sys
sys.path.insert(0, '/mnt/extra-addons')
import os
modules = [d for d in os.listdir('/mnt/extra-addons') if os.path.isdir(os.path.join('/mnt/extra-addons', d)) and 'openeducat' in d.lower()]
if modules:
    print('✅ Modules OpenEduCat trouvés:', ', '.join(modules))
else:
    print('⚠️  Aucun module OpenEduCat détecté')
" 2>&1
echo ""

echo "5. Vérification des droits:"
ls -ld /mnt/extra-addons 2>/dev/null
echo ""

echo "Diagnostic terminé."
