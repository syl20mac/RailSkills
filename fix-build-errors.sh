#!/bin/bash

# Script pour corriger les erreurs "Multiple commands produce"
# Ce script doit être exécuté depuis le répertoire racine du projet

echo "🔧 Correction des erreurs de build Xcode..."

# Liste des extensions de fichiers à exclure du bundle
EXTENSIONS_TO_EXCLUDE=(
    "*.md"
    "*.sh"
    "*.xcconfig"
    "*.txt"
    "*.html"
    "*.js"
    "*.yml"
    "*.yaml"
    "*.example"
    "*.template"
    "*.xlsx"
    "*.png" # Sauf les assets réels
    "*.code-workspace"
    ".gitignore"
    ".swiftformat"
    ".cursorrules"
    "package.json"
    "server.js"
    "utils.js"
)

echo "⚠️  ATTENTION : Ce script nécessite une intervention manuelle dans Xcode"
echo ""
echo "📋 Instructions :"
echo "1. Ouvrez RailSkills.xcodeproj dans Xcode"
echo "2. Sélectionnez le projet dans le navigateur"
echo "3. Sélectionnez la target 'RailSkills'"
echo "4. Allez dans l'onglet 'Build Phases'"
echo "5. Développez 'Copy Bundle Resources'"
echo "6. Supprimez TOUS les fichiers suivants :"
echo ""

# Liste tous les fichiers problématiques
echo "   📄 Fichiers de documentation (.md)"
echo "   🔧 Scripts shell (.sh)"
echo "   ⚙️  Fichiers de configuration (.xcconfig, .json, .yml)"
echo "   📝 Templates et exemples (.txt, .template, .example)"
echo "   🌐 Fichiers web (server.js, utils.js, .html)"
echo "   📊 Fichiers Excel (.xlsx)"
echo "   🔍 Fichiers de configuration d'outils (.gitignore, .swiftformat, .cursorrules)"
echo ""
echo "7. Gardez UNIQUEMENT :"
echo "   ✅ Info.plist (si généré automatiquement)"
echo "   ✅ Assets.xcassets"
echo "   ✅ Localizable.strings"
echo "   ✅ questions_*.json (utilisés par l'app)"
echo ""
echo "8. Nettoyez le build : Cmd+Shift+K ou Product > Clean Build Folder"
echo "9. Recompilez : Cmd+B"
echo ""

# Vérifie si le fichier projet existe
if [ -f "RailSkills.xcodeproj/project.pbxproj" ]; then
    echo "✅ Fichier projet trouvé : RailSkills.xcodeproj"
    echo ""
    echo "💡 Astuce : Dans 'Copy Bundle Resources', vous pouvez :"
    echo "   • Sélectionner plusieurs fichiers avec Cmd+Clic"
    echo "   • Tous les supprimer d'un coup avec la touche Suppr"
    echo "   • Utiliser le champ de recherche pour filtrer par extension"
    echo ""
else
    echo "❌ Fichier projet non trouvé. Assurez-vous d'être dans le bon répertoire."
    exit 1
fi

# Crée une sauvegarde du fichier projet
echo "💾 Création d'une sauvegarde du fichier projet..."
cp "RailSkills.xcodeproj/project.pbxproj" "RailSkills.xcodeproj/project.pbxproj.backup"
echo "✅ Sauvegarde créée : project.pbxproj.backup"
echo ""

echo "⚡ Après avoir suivi ces étapes, vos erreurs de build devraient être corrigées !"
