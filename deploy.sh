#!/bin/bash

# Script de déploiement pour les applications Nawel et Menus
# Usage: ./deploy.sh [nawel|menus|all]

set -e  # Exit on error

APP=${1:-all}

echo "🚀 Démarrage du déploiement : $APP"

# Fonction pour déployer une application
deploy_app() {
    local app_name=$1
    echo "📦 Mise à jour de $app_name..."

    cd ./$app_name
    git pull origin master
    cd ..
}

# Fonction pour reconstruire les conteneurs
rebuild_containers() {
    local services=$1
    echo "🔨 Reconstruction des conteneurs: $services"
    docker-compose -f docker-compose.production.yml up -d --build $services
}

# Déploiement selon l'argument
case $APP in
    nawel)
        deploy_app "nawel"
        rebuild_containers "nawel-backend nawel-frontend"
        ;;
    menus)
        deploy_app "menus"
        rebuild_containers "menus-backend menus-frontend"
        ;;
    all)
        deploy_app "nawel"
        deploy_app "menus"
        rebuild_containers ""
        ;;
    *)
        echo "❌ Usage: $0 [nawel|menus|all]"
        exit 1
        ;;
esac

# Nettoyage des images inutilisées
echo "🧹 Nettoyage des images Docker inutilisées..."
docker image prune -f

echo "✅ Déploiement terminé!"
echo "📊 Status des conteneurs:"
docker-compose -f docker-compose.production.yml ps
