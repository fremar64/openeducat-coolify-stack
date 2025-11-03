#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Installation de OpenEduCat pour Odoo 18..."

# Nettoyer la destination
rm -rf /mnt/extra-addons/*

# Cloner le dépôt officiel dans un répertoire temporaire
tmpdir=$(mktemp -d)
git clone --depth 1 https://github.com/openeducat/openeducat_erp.git "$tmpdir/openeducat_erp"

# Déployer les modules dans /mnt/extra-addons (WORKDIR défini dans Dockerfile)
cp -a "$tmpdir/openeducat_erp/." /mnt/extra-addons/
rm -rf "$tmpdir"

echo "✅ OpenEduCat installé dans /mnt/extra-addons"
