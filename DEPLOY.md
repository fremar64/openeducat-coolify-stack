# 🚀 Guide de déploiement Coolify

Ce guide vous explique comment déployer OpenEduCat sur votre VPS Contabo via Coolify.

## 📋 Prérequis

- VPS Contabo avec Coolify installé
- Nom de domaine pointant vers votre VPS
- Accès administrateur à Coolify

## 🎯 Étapes de déploiement

### 1. Configuration de l'application dans Coolify

1. **Connectez-vous à votre interface Coolify**
   ```
   https://votre-serveur.com:8080
   ```

2. **Créer une nouvelle application**
   - Cliquez sur **"New Application"**
   - Sélectionnez **"Git Based"** 
   - Choisissez **"Public Repository"**

3. **Configuration du repository**
   ```
   Repository URL: https://github.com/fremar64/openeducat-coolify-stack
   Branch: main
   Build Pack: Docker Compose
   Compose File: docker-compose.coolify.yml
   Port: 8069
   ```

### 2. Variables d'environnement

Dans Coolify, allez dans **Environment Variables** et ajoutez :

```bash
# Configuration base de données
POSTGRES_PASSWORD=VotreMotDePassePostgreSQLSecurise123!
DB_NAME=odoo
DB_USER=odoo
DB_HOST=db
DB_PORT=5432

# Configuration Odoo
ODOO_ADMIN_PASSWORD=VotreMotDePasseAdminOdooSecurise456!

# Configuration domaine
DOMAIN=openeducat.votre-domaine.com
ADMIN_EMAIL=admin@votre-domaine.com

# Configuration backup (optionnel)
RCLONE_DROPBOX_TOKEN={"access_token":"votre_token"...}
```

⚠️ **Important** : Remplacez TOUS les mots de passe par des valeurs sécurisées !

### 3. Configuration du domaine

1. **Ajouter votre domaine**
   - Dans l'onglet **"Domains"**
   - Ajoutez : `openeducat.votre-domaine.com`
   - Coolify configurera automatiquement Let's Encrypt

2. **Configuration DNS** (sur votre registrar)
   ```
   Type: A
   Name: openeducat
   Value: IP_DE_VOTRE_VPS_CONTABO
   ```

### 4. Déploiement

1. Cliquez sur **"Deploy"**
2. Surveillez les logs de déploiement
3. Le processus prend ~5-10 minutes

### 5. Première connexion

Une fois déployé :

1. **Accédez à votre instance**
   ```
   https://openeducat.votre-domaine.com
   ```

2. **Connexion initiale**
   - Email : `admin`
   - Mot de passe : Celui défini dans `ODOO_ADMIN_PASSWORD`

3. **Installation des modules OpenEduCat**
   - Allez dans **Apps**
   - Recherchez "OpenEduCat"
   - Installez les modules requis

## 🔧 Configuration post-déploiement

### Installation des modules OpenEduCat

1. **Modules de base recommandés** :
   - `openeducat_core` - Module principal
   - `openeducat_admission` - Gestion des admissions
   - `openeducat_student` - Gestion des étudiants
   - `openeducat_faculty` - Gestion du corps enseignant

2. **Modules optionnels** :
   - `openeducat_library` - Gestion de bibliothèque
   - `openeducat_assignment` - Gestion des devoirs
   - `openeducat_exam` - Gestion des examens
   - `openeducat_fees` - Gestion des frais

### Configuration initiale

1. **Configuration de l'établissement**
   - Nom de l'école/université
   - Adresse et contacts
   - Logo et branding

2. **Création des utilisateurs**
   - Administrateurs
   - Enseignants
   - Personnel administratif

3. **Structure académique**
   - Facultés/Départements
   - Programmes d'études
   - Cours et matières

## 💾 Sauvegardes

### Activation des sauvegardes automatiques

Si vous souhaitez activer les sauvegardes :

1. **Configurez rclone** (exemple avec Dropbox) :
   ```bash
   # Sur votre machine locale
   rclone config
   # Suivez les instructions pour Dropbox
   # Copiez le token généré dans RCLONE_DROPBOX_TOKEN
   ```

2. **Décommentez le service backup** dans docker-compose.coolify.yml

3. **Redéployez** l'application

### Sauvegardes manuelles

Via SSH sur votre serveur :

```bash
# Backup de la base de données
docker exec openeducat_db pg_dump -U odoo -d odoo -f /tmp/backup.sql

# Backup des fichiers
docker exec openeducat_web cp -r /var/lib/odoo /tmp/odoo_files
```

## 🛠️ Maintenance

### Mise à jour de l'application

1. **Via Coolify** :
   - Allez dans votre application
   - Cliquez sur **"Deploy"** pour redéployer

2. **Mise à jour des modules** :
   ```bash
   # Via SSH sur le serveur
   docker exec openeducat_web odoo -u all -d odoo --stop-after-init
   ```

### Surveillance

- **Logs** : Consultables dans l'interface Coolify
- **Monitoring** : Coolify fournit des métriques de base
- **Alertes** : Configurables via Coolify

## 🔒 Sécurité

### Recommandations essentielles

1. **Mots de passe forts** (20+ caractères avec symboles)
2. **Certificats SSL** automatiques via Let's Encrypt
3. **Sauvegardes régulières** et testées
4. **Mises à jour système** régulières
5. **Accès limité** aux comptes administrateur

### Firewall Contabo

Assurez-vous que seuls les ports nécessaires sont ouverts :
- Port 80 (HTTP → HTTPS redirect)
- Port 443 (HTTPS)
- Port 22 (SSH - avec clés uniquement)

## 🆘 Dépannage

### Problèmes courants

1. **Application ne démarre pas**
   - Vérifiez les logs dans Coolify
   - Contrôlez les variables d'environnement
   - Vérifiez que le domaine pointe vers le bon IP

2. **Base de données inaccessible**
   - Vérifiez `POSTGRES_PASSWORD`
   - Regardez les logs du container PostgreSQL

3. **Modules OpenEduCat manquants**
   - Reconstruisez l'image Docker
   - Vérifiez que les modules sont bien installés

### Logs utiles

```bash
# Logs de l'application Odoo
docker logs openeducat_web

# Logs de la base de données
docker logs openeducat_db

# Logs complets via Coolify
# Consultez directement l'interface web
```

## 📞 Support

- **Documentation** : Consultez le README.md principal
- **Issues GitHub** : https://github.com/fremar64/openeducat-coolify-stack/issues
- **OpenEduCat Community** : https://openeducat.org/
- **Coolify Documentation** : https://coolify.io/docs

---

**Bon déploiement ! 🎉**