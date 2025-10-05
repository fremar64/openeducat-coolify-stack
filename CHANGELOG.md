# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

## [1.0.0] - 2025-10-05

### 🚀 Ajouté
- Configuration Docker Compose complète pour OpenEduCat (Odoo 18)
- Support optimisé pour Coolify avec `docker-compose.coolify.yml`
- Configuration PostgreSQL 16 avec healthchecks
- Service Redis pour la cache
- Service de backup automatique avec rclone
- Support Traefik pour SSL automatique (optionnel)
- Dockerfile personnalisé avec dépendances OpenEduCat
- Configuration Odoo complète avec paramètres optimisés
- Script d'installation automatique OpenEduCat
- Script d'initialisation pour la première configuration
- Makefile avec commandes utiles pour le développement
- Documentation complète (README.md, DEPLOY.md)
- Variables d'environnement d'exemple (`.env.example`)
- Gitignore complet pour les fichiers sensibles

### 🛠️ Configuration
- Support multi-environnement (local/Coolify)
- Variables d'environnement flexibles
- Volumes persistants pour données et addons
- Profiles Docker Compose (backup, traefik)
- Healthchecks pour tous les services critiques

### 📚 Documentation
- Guide de déploiement Coolify détaillé
- Instructions d'installation locale
- Commandes Make pour la gestion du projet
- Exemples de configuration
- Guide de dépannage

### 🔒 Sécurité
- Mots de passe sécurisés dans les variables d'environnement
- Isolation des services via réseaux Docker
- Configuration SSL/TLS automatique
- Sauvegarde chiffrée optionnelle

---

## Format du changelog

Ce projet suit le [Semantic Versioning](https://semver.org/) et le format [Keep a Changelog](https://keepachangelog.com/).

### Types de changements
- **Ajouté** : nouvelles fonctionnalités
- **Modifié** : changements dans les fonctionnalités existantes
- **Obsolète** : fonctionnalités qui seront supprimées
- **Supprimé** : fonctionnalités supprimées
- **Corrigé** : corrections de bugs
- **Sécurité** : en cas de vulnérabilités