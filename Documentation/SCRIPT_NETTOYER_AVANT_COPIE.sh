#!/bin/bash
#
# Script pour nettoyer le projet Xcode avant de le copier sur le Mac mini
# Supprime les fichiers utilisateur spécifiques qui peuvent causer des problèmes
#

echo "🧹 Nettoyage du projet RailSkills avant copie..."
echo ""

# Aller dans le répertoire du projet
cd "$(dirname "$0")/.."

# Vérifier qu'on est dans le bon répertoire
if [ ! -f "RailSkills.xcodeproj/project.pbxproj" ]; then
    echo "❌ Erreur : Ce script doit être exécuté depuis le répertoire du projet"
    exit 1
fi

# Supprimer les fichiers utilisateur Xcode
echo "📁 Suppression des fichiers utilisateur Xcode..."
find . -name "*.xcuserstate" -delete 2>/dev/null
find . -name "xcuserdata" -type d -exec rm -rf {} + 2>/dev/null
find . -name "DerivedData" -type d -exec rm -rf {} + 2>/dev/null

# Supprimer les builds
echo "📦 Suppression des builds..."
rm -rf build/ 2>/dev/null
rm -rf ~/Library/Developer/Xcode/DerivedData/RailSkills-* 2>/dev/null

# Supprimer les fichiers système
echo "🗑️  Suppression des fichiers système..."
find . -name ".DS_Store" -delete 2>/dev/null

# Compter les fichiers supprimés
echo ""
echo "✅ Nettoyage terminé !"
echo ""
echo "📊 Taille du projet après nettoyage :"
du -sh . 2>/dev/null

echo ""
echo "✅ Le projet est maintenant prêt pour être copié sur le Mac mini"
echo ""
echo "💡 Pour copier via rsync (recommandé) :"
echo "   rsync -av --exclude='.git' --exclude='node_modules' \\"
echo "     \"$(pwd)/\" \\"
echo "     macmini-railskills:/Users/sylvain/Applications/RailSkills/RailSkills-iOS/"
echo ""





























