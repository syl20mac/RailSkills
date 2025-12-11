#!/bin/bash

# Script pour préparer un dépôt public avec les fichiers nécessaires pour Apple
# Usage: ./prepare-public-repo.sh

set -e

echo "🚀 Préparation du dépôt public RailSkills-Public..."

# Créer le dossier pour le dépôt public
PUBLIC_REPO_DIR="../RailSkills-Public"
mkdir -p "$PUBLIC_REPO_DIR"

echo "📁 Copie des fichiers publics..."

# Copier les fichiers nécessaires
cp PRIVACY_POLICY.md "$PUBLIC_REPO_DIR/"
cp SUPPORT.md "$PUBLIC_REPO_DIR/"
cp index.md "$PUBLIC_REPO_DIR/"
cp _config.yml "$PUBLIC_REPO_DIR/"

# Copier le dossier _layouts
cp -r _layouts "$PUBLIC_REPO_DIR/"

# Copier les autres fichiers de support (optionnels)
if [ -f "changelog.md" ]; then
    cp changelog.md "$PUBLIC_REPO_DIR/"
fi

if [ -f "ideas.md" ]; then
    cp ideas.md "$PUBLIC_REPO_DIR/"
fi

if [ -f "new-bug.md" ]; then
    cp new-bug.md "$PUBLIC_REPO_DIR/"
fi

if [ -f "new-feature.md" ]; then
    cp new-feature.md "$PUBLIC_REPO_DIR/"
fi

# Créer un README pour le dépôt public
cat > "$PUBLIC_REPO_DIR/README.md" << 'EOF'
# RailSkills - Fichiers Publics

Ce dépôt contient uniquement les fichiers publics nécessaires pour la validation App Store.

## 📄 Fichiers disponibles

- **[Politique de Confidentialité](PRIVACY_POLICY.md)** - Politique de confidentialité de l'application
- **[Support](SUPPORT.md)** - Page de support et FAQ
- **[Accueil](index.md)** - Page d'accueil

## 🌐 GitHub Pages

Ce dépôt est configuré pour GitHub Pages. Une fois activé, les fichiers seront accessibles sur :
- `https://syl20mac.github.io/RailSkills-Public/`

## 📱 URLs pour App Store Connect

Une fois GitHub Pages activé, utilisez ces URLs :

- **Privacy Policy URL** : `https://syl20mac.github.io/RailSkills-Public/PRIVACY_POLICY.html`
- **Support URL** : `https://syl20mac.github.io/RailSkills-Public/SUPPORT.html`

## 🔒 Sécurité

Ce dépôt est **public** et ne contient que des fichiers d'information. Aucun code source ou secret n'est présent.

---

**Application :** RailSkills  
**Version :** 1.2+  
**Développeur :** Sylvain GALLON
EOF

# Créer un .gitignore minimal
cat > "$PUBLIC_REPO_DIR/.gitignore" << 'EOF'
# macOS
.DS_Store
**/.DS_Store

# Editor
.vscode/
.idea/
*.swp
*~
EOF

echo "✅ Fichiers copiés dans $PUBLIC_REPO_DIR"
echo ""
echo "📝 Prochaines étapes :"
echo "1. Allez sur https://github.com/new"
echo "2. Créez un nouveau dépôt nommé 'RailSkills-Public' (PUBLIC)"
echo "3. Dans le dossier $PUBLIC_REPO_DIR, exécutez :"
echo "   cd $PUBLIC_REPO_DIR"
echo "   git init"
echo "   git add ."
echo "   git commit -m 'Initial commit: Fichiers publics pour App Store'"
echo "   git branch -M main"
echo "   git remote add origin https://github.com/syl20mac/RailSkills-Public.git"
echo "   git push -u origin main"
echo ""
echo "4. Activez GitHub Pages :"
echo "   - Allez sur https://github.com/syl20mac/RailSkills-Public/settings/pages"
echo "   - Source: Deploy from a branch"
echo "   - Branch: main, folder: / (root)"
echo "   - Save"
echo ""
echo "5. Attendez quelques minutes, puis utilisez les URLs dans App Store Connect"

