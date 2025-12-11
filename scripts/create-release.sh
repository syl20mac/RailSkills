#!/bin/bash

# Script pour automatiser la création de releases GitHub depuis Xcode
# Usage: Ajouter ce script dans Xcode → Build Phases → Run Script

set -e

# Configuration
GITHUB_REPO="syl20mac/RailSkills"
GITHUB_TOKEN="${GITHUB_TOKEN}"  # À définir dans les variables d'environnement Xcode

# Récupérer la version depuis Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${PROJECT_DIR}/Configs/Info.plist")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${PROJECT_DIR}/Configs/Info.plist")

# Créer le tag
TAG="v${VERSION}"
TAG_MESSAGE="Version ${VERSION} (Build ${BUILD_NUMBER})"

echo "🚀 Création de la release ${TAG}..."

# Vérifier si le tag existe déjà
if git rev-parse "${TAG}" >/dev/null 2>&1; then
    echo "⚠️  Le tag ${TAG} existe déjà. Skip."
    exit 0
fi

# Créer le tag Git
git tag -a "${TAG}" -m "${TAG_MESSAGE}"

# Push le tag vers GitHub
git push origin "${TAG}"

echo "✅ Tag ${TAG} créé et pushé vers GitHub"

# Optionnel : Créer la release via GitHub API (nécessite GITHUB_TOKEN)
if [ -n "${GITHUB_TOKEN}" ]; then
    echo "📦 Création de la release sur GitHub..."
    
    RELEASE_NOTES=$(cat <<EOF
## 🎉 Version ${VERSION} (Build ${BUILD_NUMBER})

### ✨ Nouveautés
- Voir le changelog pour les détails

### 📱 Compatibilité
- iOS 18.0+
- iPadOS 18.0+

### 📄 Documentation
- Privacy Policy : https://syl20mac.github.io/RailSkills-Public/PRIVACY_POLICY.html
- Support : https://syl20mac.github.io/RailSkills-Public/SUPPORT.html
EOF
)
    
    # Créer la release via GitHub API
    curl -X POST \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${GITHUB_REPO}/releases" \
        -d "{
            \"tag_name\": \"${TAG}\",
            \"name\": \"Version ${VERSION}\",
            \"body\": $(echo "${RELEASE_NOTES}" | jq -Rs .),
            \"draft\": false,
            \"prerelease\": false
        }"
    
    echo "✅ Release créée sur GitHub"
else
    echo "ℹ️  GITHUB_TOKEN non défini. Tag créé, release à créer manuellement sur GitHub."
    echo "   Allez sur: https://github.com/${GITHUB_REPO}/releases/new"
fi

