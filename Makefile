# OpenEduCat Makefile
# Commandes utiles pour gérer votre stack OpenEduCat

.PHONY: help install start stop restart logs backup clean

# Variables
COMPOSE_FILE = docker-compose.yml
COOLIFY_COMPOSE_FILE = docker-compose.coolify.yml
PROJECT_NAME = openeducat
# Détecter la commande docker compose (v2) par défaut
DC ?= docker compose

help: ## Afficher cette aide
	@echo "OpenEduCat - Commandes disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Installer les dépendances et initialiser
	@echo "📦 Installation d'OpenEduCat..."
	@if [ ! -f .env ]; then cp .env.example .env; echo "⚠️  Pensez à éditer le fichier .env"; fi
	@$(DC) -f $(COMPOSE_FILE) pull
	@echo "✅ Installation terminée"

start: ## Démarrer les services
	@echo "🚀 Démarrage des services OpenEduCat..."
	@$(DC) -f $(COMPOSE_FILE) up -d --build
	@echo "✅ Services démarrés"
	@echo "🌐 OpenEduCat disponible sur: http://localhost:8069"

start-coolify: ## Démarrer avec la configuration Coolify
	@echo "🚀 Démarrage avec configuration Coolify..."
	@$(DC) -f $(COOLIFY_COMPOSE_FILE) up -d --build
	@echo "✅ Services démarrés"

stop: ## Arrêter les services
	@echo "⏹️  Arrêt des services..."
	@$(DC) -f $(COMPOSE_FILE) down
	@echo "✅ Services arrêtés"

restart: ## Redémarrer les services
	@echo "🔄 Redémarrage des services..."
	@$(DC) -f $(COMPOSE_FILE) restart
	@echo "✅ Services redémarrés"

logs: ## Voir les logs
	@$(DC) -f $(COMPOSE_FILE) logs -f

logs-odoo: ## Voir les logs d'Odoo uniquement
	@$(DC) -f $(COMPOSE_FILE) logs -f odoo

backup: ## Faire une sauvegarde manuelle
	@echo "💾 Sauvegarde en cours..."
	@$(DC) -f $(COMPOSE_FILE) exec db pg_dump -U odoo -d odoo -F c -b -v -f /tmp/backup_$(shell date +%Y%m%d_%H%M%S).dump
	@echo "✅ Sauvegarde terminée"

shell-odoo: ## Accéder au shell d'Odoo
	@$(DC) -f $(COMPOSE_FILE) exec odoo bash

shell-db: ## Accéder au shell PostgreSQL
	@$(DC) -f $(COMPOSE_FILE) exec db psql -U odoo -d odoo

update-modules: ## Mettre à jour les modules OpenEduCat
	@echo "🔄 Mise à jour des modules..."
	@$(DC) -f $(COMPOSE_FILE) exec odoo odoo -u all -d odoo --stop-after-init --no-http

clean: ## Nettoyer les containers et volumes
	@echo "🧹 Nettoyage..."
	@$(DC) -f $(COMPOSE_FILE) down -v
	@docker system prune -f
	@echo "✅ Nettoyage terminé"

status: ## Voir le statut des services
	@$(DC) -f $(COMPOSE_FILE) ps

# Commandes de développement
dev-setup: ## Configuration pour le développement
	@echo "🛠️  Configuration développement..."
	@mkdir -p addons
	@git clone https://github.com/openeducat/openeducat_erp.git addons/openeducat_erp || echo "Dépôt déjà cloné"
	@echo "✅ Configuration développement terminée"