#!/bin/bash
set -e

echo "🚀 Installation de OpenEduCat pour Odoo 18..."

# Cloner le dépôt officiel
git clone --depth 1 https://github.com/openeducat/openeducat_erp.git

# Déplacer les modules vers /mnt/extra-addons
mv openeducat_erp/* /mnt/extra-addons/
rm -rf openeducat_erp

echo "✅ OpenEduCat installé dans /mnt/extra-addons"
