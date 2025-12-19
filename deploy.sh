#!/bin/bash

# Script de déploiement automatique pour Menus et Nawel
# Usage: ./deploy.sh [--rebuild] [--menus-only] [--nawel-only]

set -e  # Arrêter en cas d'erreur

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les logs
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENUS_DIR="$SCRIPT_DIR/../menus"
NAWEL_DIR="$SCRIPT_DIR/../nawel"
REBUILD=false
MENUS_ONLY=false
NAWEL_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --rebuild)
            REBUILD=true
            shift
            ;;
        --menus-only)
            MENUS_ONLY=true
            shift
            ;;
        --nawel-only)
            NAWEL_ONLY=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --rebuild       Force le rebuild complet des images Docker"
            echo "  --menus-only    Déployer uniquement Menus"
            echo "  --nawel-only    Déployer uniquement Nawel"
            echo "  --help          Afficher cette aide"
            echo ""
            echo "Exemples:"
            echo "  $0                    # Déployer tout sans rebuild"
            echo "  $0 --rebuild          # Déployer tout avec rebuild"
            echo "  $0 --menus-only       # Déployer uniquement Menus"
            exit 0
            ;;
        *)
            log_error "Option inconnue: $1"
            echo "Utilisez --help pour voir les options disponibles"
            exit 1
            ;;
    esac
done

log_info "=========================================="
log_info "🚀 Début du déploiement"
log_info "=========================================="

# 1. Pull les dernières modifications
if [ "$NAWEL_ONLY" = false ]; then
    log_info "📥 Pull des modifications pour Menus..."
    cd "$MENUS_DIR"
    git pull origin master
    log_success "Menus mis à jour"
fi

if [ "$MENUS_ONLY" = false ]; then
    log_info "📥 Pull des modifications pour Nawel..."
    cd "$NAWEL_DIR"
    git pull origin master
    log_success "Nawel mis à jour"
fi

log_info "📥 Pull des modifications pour Infrastructure..."
cd "$SCRIPT_DIR"
git pull origin master
log_success "Infrastructure mis à jour"

# 2. Basculer vers les migrations MySQL pour Menus (production)
if [ "$NAWEL_ONLY" = false ]; then
    log_info "🔄 Basculement vers les migrations MySQL pour Menus..."
    cd "$MENUS_DIR/backend"

    # Sauvegarder les migrations actuelles (SQLite) si elles existent
    if [ -d "Menus.Api/Migrations" ] && [ "$(ls -A Menus.Api/Migrations/*.cs 2>/dev/null)" ]; then
        log_info "   Sauvegarde des migrations SQLite..."
        mkdir -p Menus.Api/Migrations/_backup/SQLite
        cp -f Menus.Api/Migrations/*.cs Menus.Api/Migrations/_backup/SQLite/ 2>/dev/null || true
    fi

    # Nettoyer le dossier Migrations (actives)
    rm -f Menus.Api/Migrations/*.cs 2>/dev/null || true

    # Copier les migrations MySQL
    if [ -d "Menus.Api/Migrations/_backup/MySQL" ] && [ "$(ls -A Menus.Api/Migrations/_backup/MySQL/*.cs 2>/dev/null)" ]; then
        log_info "   Activation des migrations MySQL..."
        cp -f Menus.Api/Migrations/_backup/MySQL/*.cs Menus.Api/Migrations/
        log_success "Migrations MySQL activées pour la production"
    else
        log_error "❌ Migrations MySQL introuvables dans Menus.Api/Migrations/_backup/MySQL/"
        log_error "   Utilisez .\add-migration.ps1 pour générer les migrations MySQL"
        exit 1
    fi
fi

if [ "$MENUS_ONLY" = false ]; then
    log_info "🔄 Basculement vers les migrations MySQL pour Nawel..."
    cd "$NAWEL_DIR/backend"

    # Sauvegarder les migrations actuelles (SQLite) si elles existent
    if [ -d "Nawel.Api/Migrations" ] && [ "$(ls -A Nawel.Api/Migrations/*.cs 2>/dev/null)" ]; then
        log_info "   Sauvegarde des migrations SQLite..."
        mkdir -p Nawel.Api/Migrations/_backup/SQLite
        cp -f Nawel.Api/Migrations/*.cs Nawel.Api/Migrations/_backup/SQLite/ 2>/dev/null || true
    fi

    # Nettoyer le dossier Migrations (actives)
    rm -f Nawel.Api/Migrations/*.cs 2>/dev/null || true

    # Copier les migrations MySQL
    if [ -d "Nawel.Api/Migrations/_backup/MySQL" ] && [ "$(ls -A Nawel.Api/Migrations/_backup/MySQL/*.cs 2>/dev/null)" ]; then
        log_info "   Activation des migrations MySQL..."
        cp -f Nawel.Api/Migrations/_backup/MySQL/*.cs Nawel.Api/Migrations/
        log_success "Migrations MySQL activées pour la production"
    else
        log_error "❌ Migrations MySQL introuvables dans Nawel.Api/Migrations/_backup/MySQL/"
        log_error "   Utilisez .\add-migration.ps1 pour générer les migrations MySQL"
        exit 1
    fi
fi

# 3. Arrêter les containers
log_info "🛑 Arrêt des containers..."
cd "$SCRIPT_DIR"
docker-compose -f docker-compose.production.yml down
log_success "Containers arrêtés"

# 4. Rebuild si nécessaire
if [ "$REBUILD" = true ]; then
    log_info "🔨 Rebuild des images Docker..."

    if [ "$MENUS_ONLY" = true ]; then
        docker-compose -f docker-compose.production.yml build --no-cache menus-backend menus-frontend
        log_success "Images Menus rebuilds"
    elif [ "$NAWEL_ONLY" = true ]; then
        docker-compose -f docker-compose.production.yml build --no-cache nawel-backend nawel-frontend
        log_success "Images Nawel rebuilds"
    else
        docker-compose -f docker-compose.production.yml build --no-cache
        log_success "Toutes les images rebuilds"
    fi
else
    log_info "ℹ️  Pas de rebuild (utilisez --rebuild pour forcer)"
fi

# 5. Démarrer les containers
log_info "▶️  Démarrage des containers..."
docker-compose -f docker-compose.production.yml up -d
log_success "Containers démarrés"

# 6. Attendre que les services soient prêts
log_info "⏳ Attente du démarrage des services..."
sleep 15

# 7. Vérifier l'état des containers
log_info "🔍 Vérification de l'état des containers..."
echo ""
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=menus\|nawel\|mysql"
echo ""

# 8. Vérifier les logs des backends pour les migrations
if [ "$NAWEL_ONLY" = false ]; then
    log_info "🗄️  Vérification des migrations Menus..."
    if docker logs menus-backend 2>&1 | tail -50 | grep -q "Database migrations completed successfully"; then
        log_success "Migrations Menus OK"
    else
        log_warning "Migrations Menus : vérifier les logs avec 'docker logs menus-backend'"
    fi
fi

if [ "$MENUS_ONLY" = false ]; then
    log_info "🗄️  Vérification des migrations Nawel..."
    if docker logs nawel-backend 2>&1 | tail -50 | grep -q "Database migrations completed successfully"; then
        log_success "Migrations Nawel OK"
    else
        log_warning "Migrations Nawel : vérifier les logs avec 'docker logs nawel-backend'"
    fi
fi

# 9. Tester les endpoints
log_info "🌐 Test des endpoints..."

if [ "$NAWEL_ONLY" = false ]; then
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3001 | grep -q "200"; then
        log_success "Menus Frontend ✓"
    else
        log_warning "Menus Frontend : vérifier manuellement"
    fi

    if curl -s -o /dev/null -w "%{http_code}" http://localhost:5001 2>/dev/null | grep -q "200\|404"; then
        log_success "Menus Backend ✓"
    else
        log_warning "Menus Backend : vérifier manuellement"
    fi
fi

if [ "$MENUS_ONLY" = false ]; then
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 | grep -q "200"; then
        log_success "Nawel Frontend ✓"
    else
        log_warning "Nawel Frontend : vérifier manuellement"
    fi

    if curl -s -o /dev/null -w "%{http_code}" http://localhost:5000 2>/dev/null | grep -q "200\|404"; then
        log_success "Nawel Backend ✓"
    else
        log_warning "Nawel Backend : vérifier manuellement"
    fi
fi

# 10. Nettoyage
log_info "🧹 Nettoyage des images inutilisées..."
docker image prune -f > /dev/null 2>&1
log_success "Nettoyage effectué"

log_info "=========================================="
log_success "✅ Déploiement terminé avec succès !"
log_info "=========================================="
echo ""
log_info "🌍 Applications accessibles à :"
log_info "  • Menus: https://menus.nironi.com"
log_info "  • Nawel: https://nawel.nironi.com"
echo ""
log_info "📊 Pour voir les logs en temps réel :"
log_info "  • docker logs -f menus-backend"
log_info "  • docker logs -f nawel-backend"
log_info "  • docker logs -f menus-frontend"
log_info "  • docker logs -f nawel-frontend"
