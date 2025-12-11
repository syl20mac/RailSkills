#!/bin/bash

# Script rapide pour push automatique sans confirmation
# Usage: ./scripts/quick-push.sh [message]
# Conçu pour être appelé directement depuis Cursor AI

set -e

COMMIT_MESSAGE="${1:-Auto-commit depuis Cursor AI - $(date '+%Y-%m-%d %H:%M:%S')}"

# Vérifier qu'on est dans un dépôt Git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Ce répertoire n'est pas un dépôt Git"
    exit 1
fi

# Vérifier s'il y a des changements
if git diff --quiet && git diff --cached --quiet; then
    echo "ℹ️  Aucun changement détecté"
    exit 0
fi

# Ajouter, commiter et push
git add -A
git commit -m "$COMMIT_MESSAGE"
CURRENT_BRANCH=$(git branch --show-current)
git push origin "$CURRENT_BRANCH"

echo "✅ Push réussi vers GitHub ($CURRENT_BRANCH)"
