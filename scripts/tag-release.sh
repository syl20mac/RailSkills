#!/bin/bash

# Script manuel pour créer un tag Git après une archive
# Usage: ./scripts/tag-release.sh

cd "$(dirname "$0")/.."

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "Configs/Info.plist")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "Configs/Info.plist")

TAG="v${VERSION}"
TAG_MESSAGE="Version ${VERSION} (Build ${BUILD_NUMBER})"

echo "🏷️  Création du tag ${TAG}..."

# Vérifier si on est dans un dépôt Git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "⚠️  Pas un dépôt Git. Skip."
    exit 1
fi

# Vérifier si le tag existe déjà
if git rev-parse "${TAG}" >/dev/null 2>&1; then
    echo "⚠️  Le tag ${TAG} existe déjà."
    read -p "Voulez-vous le supprimer et le recréer ? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -d "${TAG}"
        git push origin ":refs/tags/${TAG}" 2>/dev/null || true
    else
        echo "ℹ️  Tag existant conservé. Skip."
        exit 0
    fi
fi

# Créer le tag
git tag -a "${TAG}" -m "${TAG_MESSAGE}"

# Demander si on veut push
read -p "Voulez-vous push le tag vers GitHub maintenant ? (Y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    git push origin "${TAG}"
    echo "✅ Tag ${TAG} créé et pushé vers GitHub"
else
    echo "✅ Tag ${TAG} créé localement"
    echo "💡 Pour push plus tard: git push origin ${TAG}"
fi

echo ""
echo "📦 Créez maintenant la release sur:"
echo "   https://github.com/syl20mac/RailSkills/releases/new"





















