#!/bin/bash

# Script simplifié pour créer automatiquement un tag Git lors d'un build Release
# Usage: Ajouter dans Xcode → Build Phases → Run Script (après "Copy Bundle Resources")

set -e

# Ne s'exécuter que pour les builds Release
if [ "${CONFIGURATION}" != "Release" ]; then
    echo "ℹ️  Build ${CONFIGURATION} - Skip tagging (uniquement pour Release)"
    exit 0
fi

# Récupérer la version depuis Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${PROJECT_DIR}/Configs/Info.plist")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${PROJECT_DIR}/Configs/Info.plist")

TAG="v${VERSION}"
TAG_MESSAGE="Version ${VERSION} (Build ${BUILD_NUMBER}) - Auto-tagged from Xcode"

echo "🏷️  Création du tag ${TAG}..."

# Vérifier si on est dans un dépôt Git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "⚠️  Pas un dépôt Git. Skip."
    exit 0
fi

# Vérifier si le tag existe déjà
if git rev-parse "${TAG}" >/dev/null 2>&1; then
    echo "ℹ️  Le tag ${TAG} existe déjà. Skip."
    exit 0
fi

# Créer le tag
git tag -a "${TAG}" -m "${TAG_MESSAGE}"

# Push le tag (optionnel - peut être fait manuellement)
# git push origin "${TAG}"

echo "✅ Tag ${TAG} créé localement"
echo "💡 Pour push vers GitHub: git push origin ${TAG}"

