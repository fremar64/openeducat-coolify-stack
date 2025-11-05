# 🔄 Guide de Sauvegarde OpenEduCat

Ce document explique comment activer et configurer les sauvegardes automatiques pour votre instance OpenEduCat.

## 📋 Vue d'ensemble

Le système de backup inclut :
- **Sauvegarde PostgreSQL** : Dump complet de la base de données toutes les 24h
- **Rétention automatique** : Conservation des 7 derniers jours
- **Synchronisation cloud (optionnelle)** : Upload vers Dropbox via rclone
- **Backup des fichiers** : Copie du filestore Odoo (documents, pièces jointes)

## ⚙️ Activation dans Coolify

### 1. Ajouter la variable d'environnement

Dans l'interface Coolify de votre application :

1. Aller dans **Environment Variables**
2. Ajouter une nouvelle variable :
   ```
   COMPOSE_PROFILES=backup
   ```
3. Cliquer sur **Save**

### 2. Redéployer l'application

Cliquer sur **Deploy** pour que le service backup démarre.

### 3. Vérifier le démarrage

Dans les logs du service `backup`, vous devriez voir :

```
🚀 Démarrage du service de backup automatique...
Configuration:
  - Base de données: odoo
  - Utilisateur: odoo
  - Hôte: db
  - Intervalle: 24h
  - Rétention: 7 jours
  - Stockage distant: Non configuré

📦 Installation de rclone...
✅ Dépendances installées

====================================
🔄 Début du backup à Mon Nov  4 ...
====================================
📊 Sauvegarde de la base de données PostgreSQL...
✅ Base de données sauvegardée avec succès (1.4M)
```

## ☁️ Configuration Dropbox (Optionnel)

Pour synchroniser automatiquement vers Dropbox :

### 1. Obtenir un token Dropbox

1. Aller sur https://www.dropbox.com/developers/apps
2. Créer une nouvelle app avec accès "Full Dropbox"
3. Générer un Access Token

### 2. Ajouter le token dans Coolify

Dans **Environment Variables**, ajouter :
```
RCLONE_DROPBOX_TOKEN=votre_token_ici
```

### 3. Redéployer

Après redéploiement, les backups seront automatiquement synchronisés vers :
- `Dropbox:/openeducat_backups/files/` (filestore Odoo)
- `Dropbox:/openeducat_backups/sql/` (dumps PostgreSQL)

## 📁 Localisation des backups

Les backups locaux sont stockés dans le volume `./backups/` :

```bash
# Lister les backups disponibles
ls -lh ./backups/

# Format des noms : odoo_db_YYYYMMDD_HHMMSS.dump
odoo_db_20251104_203622.dump
odoo_db_20251105_203622.dump
...
```

## 🔧 Opérations manuelles

### Créer un backup immédiat

Via le shell du service backup dans Coolify :

```bash
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
pg_dump -h db -U odoo -d odoo -F c -b -v -f /backups/manual_backup_${TIMESTAMP}.dump
```

### Lister les backups

```bash
ls -lh /backups/
```

### Vérifier la taille d'un backup

```bash
du -h /backups/odoo_db_20251104_203622.dump
```

## 🔄 Restauration d'un backup

### Étape 1 : Arrêter Odoo temporairement

Dans Coolify, arrêter le service `web`.

### Étape 2 : Restaurer la base

Via le shell du service `db` :

```bash
# Supprimer la base existante
psql -U odoo -c "DROP DATABASE IF EXISTS odoo;"

# Recréer une base vide
psql -U odoo -c "CREATE DATABASE odoo OWNER odoo;"

# Restaurer depuis le backup
pg_restore -h localhost -U odoo -d odoo -v /backups/backup_choisi.dump
```

### Étape 3 : Redémarrer Odoo

Dans Coolify, redémarrer le service `web`.

### Étape 4 : Vérifier le fonctionnement

- Se connecter à l'interface Odoo
- Vérifier l'accès admin
- Tester les fonctionnalités critiques
- Consulter les logs pour détecter des erreurs

## 📊 Monitoring# Lancer le test de restauration
test_restore.sh /backups/odoo_db_YYYYMMDD_HHMMSS.dump
```

Le script va :
1. ✅ Créer une base de test temporaire
2. ✅ Restaurer le backup dedans
3. ✅ Vérifier l'intégrité (tables, données, modules)
4. ✅ Afficher un rapport détaillé
5. ✅ Proposer de nettoyer ou garder la base de test

**Sortie attendue :**
```
======================================
🔄 TEST DE RESTAURATION BACKUP ODOO
======================================

📦 Backup sélectionné:
  Fichier: /backups/odoo_db_20251105_025254.dump
  Taille: 1.4M

🔌 Vérification de la connexion PostgreSQL...
✅ Connexion PostgreSQL OK

🗄️  Création de la base de test: odoo_test_20251105_103045
✅ Base de test créée

📥 Restauration du backup (cela peut prendre quelques minutes)...
[...logs de restauration...]
✅ Restauration terminée en 15s

🔍 Vérification de l'intégrité...
  📊 Nombre de tables: 156
  ✅ Table 'res_users': 2 lignes
  ✅ Table 'res_partner': 5 lignes
  ✅ Table 'ir_module_module': 89 lignes
  ✅ Table 'ir_model': 234 lignes
  ✅ Table 'res_company': 1 lignes

📦 Modules installés dans la base restaurée:
[...liste des modules...]

👥 Utilisateurs dans la base restaurée:
[...liste des utilisateurs...]

======================================
✅ TEST DE RESTAURATION RÉUSSI !

La base de test 'odoo_test_20251105_103045' contient:
  - 156 tables
  - Toutes les tables critiques sont présentes
  - Les données ont été restaurées
======================================

🧹 Que souhaitez-vous faire avec la base de test?
  1) La SUPPRIMER maintenant (recommandé)
  2) La GARDER pour inspection manuelle

Votre choix (1/2): _
```

### Option 2 : Base de test manuelle

Via le shell du service `db` :

```bash
# Créer une base de test
psql -U odoo -c "CREATE DATABASE odoo_test OWNER odoo;"

# Restaurer depuis le backup
pg_restore -h localhost -U odoo -d odoo_test -v /chemin/vers/backup.dump

# Vérifier
psql -U odoo -d odoo_test -c "\dt"

# Nettoyer
psql -U odoo -c "DROP DATABASE odoo_test;"
```

### Option 3 : Instance de staging

Déployer une seconde instance OpenEduCat sur Coolify avec :
- Base de données vierge
- Restauration du dernier backup
- Tests fonctionnels

### Fréquence recommandée

- **Mensuel** : Test complet avec script automatisé
- **Trimestriel** : Test sur instance de staging
- **Avant mise à jour majeure** : Toujours tester la restauration

## 🔄 Restauration en production (procédure d'urgence)

⚠️ **ATTENTION** : Cette procédure écrase la base de production !

### Étape 1 : Arrêter Odoo temporairement

Dans Coolify, arrêter le service `web`.

### Étape 2 : Restaurer la base

Via le shell du service `db` :

```bash
# Supprimer la base existante (⚠️ DESTRUCTIF !)
psql -U odoo -c "DROP DATABASE IF EXISTS odoo;"

# Recréer une base vide
psql -U odoo -c "CREATE DATABASE odoo OWNER odoo;"

## 📊 Monitoring

### Vérifier les logs de backup

Dans Coolify, consulter les logs du service `backup` :

```
====================================
🔄 Début du backup à Mon Nov  4 21:00:00
====================================
📊 Sauvegarde de la base de données PostgreSQL...
✅ Base de données sauvegardée avec succès (1.4M)

☁️  Synchronisation vers Dropbox...
  → Synchronisation des fichiers Odoo...
  ✅ Fichiers Odoo synchronisés
  → Synchronisation des dumps SQL...
  ✅ Dumps SQL synchronisés

🧹 Nettoyage des backups de plus de 7 jours...
  🗑️  Supprimé: odoo_db_20251028_210000.dump

====================================
✅ Backup terminé à Mon Nov  4 21:05:32
====================================

⏳ Prochaine sauvegarde dans 24 heures...
```

### Alertes à surveiller

- ❌ `Base de données sauvegardée failed` → Vérifier connexion DB
- ❌ `Échec de la synchronisation` → Vérifier token Dropbox
- 📦 Taille du backup anormalement petite → Possible corruption

## 🛡️ Bonnes pratiques

1. **Vérifier régulièrement** : Consulter les logs hebdomadairement
2. **Tester les restaurations** : Au moins une fois par mois
3. **Garder des backups hors-ligne** : Télécharger mensuellement un backup
4. **Documenter les restaurations** : Noter les procédures spécifiques
5. **Monitorer l'espace disque** : S'assurer que `/backups/` ne sature pas

## 🆘 Dépannage

### Le service backup ne démarre pas

1. Vérifier que `COMPOSE_PROFILES=backup` est bien défini
2. Vérifier les logs du service : "Is a directory" indique un problème de montage
3. S'assurer que l'image a été reconstruite avec `backup.sh` intégré

### Les backups sont vides (0 octets)

1. Vérifier les identifiants PostgreSQL : `POSTGRES_PASSWORD`, `DB_USER`, `DB_NAME`
2. Vérifier que le service `db` est accessible depuis `backup`
3. Consulter les logs détaillés : `docker compose logs backup`

### Synchronisation Dropbox échoue

1. Vérifier la validité du token : pas d'expiration
2. Vérifier les permissions de l'app Dropbox : "Full Dropbox" nécessaire
3. Tester manuellement : `rclone ls remote:openeducat_backups`

### Erreur "out of space"

1. Vérifier l'espace disque : `df -h`
2. Ajuster la rétention : modifier `find /backups -name '*.dump' -mtime +7 -delete` (7 → 3 jours)
3. Compresser les vieux backups : `gzip /backups/*.dump`

## 📚 Ressources

- [Documentation PostgreSQL pg_dump](https://www.postgresql.org/docs/current/app-pgdump.html)
- [Documentation PostgreSQL pg_restore](https://www.postgresql.org/docs/current/app-pgrestore.html)
- [Documentation rclone](https://rclone.org/docs/)
- [Dropbox API](https://www.dropbox.com/developers)
