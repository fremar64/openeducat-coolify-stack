# OpenEduCat Coolify Stack

Stack Docker prêt pour déployer **OpenEduCat** (basé sur Odoo 18) sur Coolify ou en local.

## 🚀 Déploiement rapide sur Coolify

### 1. Préparation
1. Forkez ce dépôt ou créez votre propre repo avec ce code
2. Dans Coolify : **New Application → Git Based → Public Repository**
   - Repository URL : `https://github.com/fremar64/openeducat-coolify-stack`
   - Branch : `main`
   - Build Pack : **Docker Compose**
   - Compose File : `docker-compose.coolify.yml` (recommandé pour Coolify)
   - Port : `8069`

### 2. Configuration des variables d'environnement
Copiez le contenu de `.env.example` dans les variables d'environnement Coolify et modifiez :

```bash
POSTGRES_PASSWORD=VotreMotDePasseSecurise123!
ODOO_ADMIN_PASSWORD=VotreMotDePasseAdmin456!
DOMAIN=votre-domaine.com
ADMIN_EMAIL=admin@votre-domaine.com
```

⚙️ `docker-compose.coolify.yml` construit l'image locale définie dans le `Dockerfile`, qui embarque déjà OpenEduCat et exécute automatiquement `init_openeducat.sh` au premier démarrage. Un fichier sentinelle est placé dans le volume `odoo_filestore` pour éviter les réinstallations lors des redéploiements.

### 3. Déploiement
1. Ajoutez votre domaine dans Coolify
2. Cliquez sur **Deploy**
3. Coolify s'occupe automatiquement des certificats SSL

## 🏠 Installation locale

### Prérequis
- Docker & Docker Compose
- Make (optionnel)

### Installation rapide
```bash
# Cloner le dépôt
git clone https://github.com/fremar64/openeducat-coolify-stack.git
cd openeducat-coolify-stack

# Configuration
cp .env.example .env
# Éditez .env avec vos valeurs

# Démarrage avec Make (recommandé)
make install
make start

# OU démarrage manuel
docker-compose up -d --build
```

Accès : http://localhost:8069
- Utilisateur : `admin`
- Mot de passe : celui défini dans `ODOO_ADMIN_PASSWORD`

## 📁 Structure du projet

```
openeducat-coolify-stack/
├── docker-compose.yml          # Configuration Docker Compose complète
├── docker-compose.coolify.yml  # Configuration optimisée pour Coolify
├── Dockerfile                  # Image personnalisée avec OpenEduCat
├── .env.example               # Variables d'environnement exemple
├── Makefile                   # Commandes utiles
├── config/
│   └── odoo.conf             # Configuration Odoo
├── addons/                   # Modules OpenEduCat personnalisés
├── backups/                  # Dossier des sauvegardes
└── install_openeducat.sh     # Script d'installation OpenEduCat
```

## 🛠️ Commandes utiles (avec Make)

```bash
make help           # Aide
make start          # Démarrer les services
make stop           # Arrêter les services
make restart        # Redémarrer
make logs           # Voir les logs
make logs-odoo      # Logs Odoo uniquement
make backup         # Sauvegarde manuelle
make shell-odoo     # Shell container Odoo
make shell-db       # Shell PostgreSQL
make update-modules # Mettre à jour les modules
make clean          # Nettoyer
make status         # Statut des services
```

## 📚 OpenEduCat / Modules

### Installation de modules supplémentaires
```bash
# Ajouter des modules dans le dossier addons/
cd addons/
git clone https://github.com/openeducat/openeducat_erp.git

# Redémarrer Odoo pour détecter les nouveaux modules
make restart
```

### Modules OpenEduCat inclus
- **openeducat_core** : Module de base
- **openeducat_admission** : Gestion des admissions
- **openeducat_student** : Gestion des étudiants
- **openeducat_faculty** : Gestion du corps enseignant
- **openeducat_library** : Gestion de bibliothèque
- Et bien d'autres...

## 💾 Sauvegardes

### Automatiques
Le service `backup` s'exécute quotidiennement et :
- Crée un dump PostgreSQL
- Sauvegarde les fichiers Odoo
- Synchronise avec un stockage distant (rclone)

### Configuration du stockage distant
Configurez rclone dans `.env` :
```bash
RCLONE_DROPBOX_TOKEN={"access_token":"votre_token"...}
```

### Sauvegarde manuelle
```bash
make backup
```

## 🔧 Configuration avancée

### Variables d'environnement importantes
| Variable | Description | Défaut |
|----------|-------------|---------|
| `POSTGRES_PASSWORD` | Mot de passe PostgreSQL | - |
| `ODOO_ADMIN_PASSWORD` | Mot de passe admin Odoo | - |
| `DOMAIN` | Domaine de votre instance | localhost |
| `ADMIN_EMAIL` | Email admin pour SSL | - |
| `DB_NAME` | Nom de la base | odoo |
| `DB_USER` | Utilisateur DB | odoo |

### Personnalisation Odoo
Éditez `config/odoo.conf` pour personnaliser la configuration Odoo.

## 🔒 Sécurité

- Changez tous les mots de passe par défaut
- Utilisez des mots de passe forts (20+ caractères)
- Activez les sauvegardes automatiques
- Mettez à jour régulièrement les images Docker

## 🐛 Dépannage

### Vérifier les logs
```bash
make logs
make logs-odoo
```

### Reconstruire les containers
```bash
make clean
make install
make start
```

### Problèmes de permissions
```bash
sudo chown -R 101:101 ./addons
sudo chown -R 999:999 ./backups
```

## 📞 Support

- Documentation OpenEduCat : https://openeducat.org/
- Documentation Odoo : https://www.odoo.com/documentation/
- Issues GitHub : https://github.com/fremar64/openeducat-coolify-stack/issues

---

**Auteur** : Frédéric OUAMBA (CEREDIS)  
**Email** : admin@ceredis.net  
**Licence** : MIT
