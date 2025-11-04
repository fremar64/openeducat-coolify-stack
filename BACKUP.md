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
pg_restore -h localhost -U odoo -d odoo -v /path/to/backup.dump
```

### Étape 3 : Redémarrer Odoo

Dans Coolify, redémarrer le service `web`.

## 🧪 Test de restauration

Il est recommandé de tester régulièrement la restauration :

### Option 1 : Base de test locale

```bash
# Créer une base de test
psql -U odoo -c "CREATE DATABASE odoo_test OWNER odoo;"

# Restaurer dedans
pg_restore -h db -U odoo -d odoo_test -v /backups/odoo_db_YYYYMMDD_HHMMSS.dump

# Vérifier
psql -U odoo -d odoo_test -c "\dt"

# Nettoyer
psql -U odoo -c "DROP DATABASE odoo_test;"
```

### Option 2 : Instance de staging

Déployer une seconde instance OpenEduCat sur Coolify avec :
- Base de données vierge
- Restauration du dernier backup
- Tests fonctionnels

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
