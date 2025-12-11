#!/bin/bash

# Script pour pousser automatiquement les changements vers GitHub
# Usage: ./scripts/auto-push-github.sh [message de commit]
# Exemple: ./scripts/auto-push-github.sh "Mise à jour de la documentation"

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# Vérifier qu'on est dans un dépôt Git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    error "Ce répertoire n'est pas un dépôt Git"
    exit 1
fi

# Récupérer le message de commit (optionnel)
COMMIT_MESSAGE="${1:-Auto-commit depuis Cursor AI}"

info "🚀 Démarrage du push automatique vers GitHub..."

# Vérifier s'il y a des changements
if git diff --quiet && git diff --cached --quiet; then
    warning "Aucun changement détecté. Rien à commiter."
    exit 0
fi

# Afficher le statut
info "📊 Statut actuel du dépôt:"
git status --short

# Demander confirmation (optionnel - peut être désactivé)
read -p "Voulez-vous continuer avec le commit et le push? (o/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
    warning "Opération annulée par l'utilisateur"
    exit 0
fi

# Ajouter tous les fichiers modifiés
info "📦 Ajout des fichiers modifiés..."
git add -A

# Créer le commit
info "💾 Création du commit..."
git commit -m "$COMMIT_MESSAGE" || {
    error "Erreur lors de la création du commit"
    exit 1
}

# Récupérer la branche actuelle
CURRENT_BRANCH=$(git branch --show-current)
info "🌿 Branche actuelle: $CURRENT_BRANCH"

# Push vers GitHub
info "⬆️  Push vers GitHub..."
git push origin "$CURRENT_BRANCH" || {
    error "Erreur lors du push vers GitHub"
    error "Vérifiez votre connexion et vos permissions"
    exit 1
}

success "Push réussi vers GitHub sur la branche $CURRENT_BRANCH"
info "🔗 Dépôt: https://github.com/syl20mac/RailSkills"
