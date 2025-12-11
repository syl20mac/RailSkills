# 🔧 Résoudre l'Avertissement "Run Script Build Phase"

**Avertissement :** 
```
Run script build phase 'Run Script' will be run during every build because it does not specify any outputs.
```

---

## ✅ Solution 1 : Désactiver "Based on dependency analysis" (Recommandé)

C'est la solution la plus simple pour un script de tagging.

### Dans Xcode :

1. **Ouvrir** le projet
2. **Sélectionner** le projet → **Target "RailSkills"** → **Build Phases**
3. **Sélectionner** votre "Run Script Phase"
4. **Décocher** : **"Based on dependency analysis"** ❌

**Résultat :** L'avertissement disparaîtra et le script s'exécutera uniquement lors des archives (si "Run script only when installing" est coché).

---

## ✅ Solution 2 : Ajouter des Output Files (Alternative)

Si vous voulez garder "Based on dependency analysis" activé, ajoutez un fichier de sortie.

### Dans Xcode Build Phases :

1. **Sélectionner** votre "Run Script Phase"
2. **Section "Output Files"** → **+**
3. **Ajouter** :
   ```
   $(SRCROOT)/.git/tag-created
   ```

4. **Modifier le script** pour créer ce fichier :

```bash
# Auto-tag version lors d'un build Release Archive
if [ "${CONFIGURATION}" != "Release" ]; then
    exit 0
fi

# Récupérer la version depuis Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${PROJECT_DIR}/Configs/Info.plist")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${PROJECT_DIR}/Configs/Info.plist")
TAG="v${VERSION}"

echo "🏷️  Création du tag ${TAG}..."

# Vérifier si on est dans un dépôt Git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "⚠️  Pas un dépôt Git. Skip."
    exit 0
fi

# Vérifier si le tag existe déjà
if git rev-parse "${TAG}" >/dev/null 2>&1; then
    echo "ℹ️  Tag ${TAG} existe déjà. Skip."
    # Créer quand même le fichier de sortie pour éviter de ré-exécuter
    touch "${SRCROOT}/.git/tag-created"
    exit 0
fi

# Créer le tag
cd "${SRCROOT}"
git tag -a "${TAG}" -m "Version ${VERSION} (Build ${BUILD_NUMBER}) - Auto-tagged from Xcode"

# Créer le fichier de sortie
touch "${SRCROOT}/.git/tag-created"

echo "✅ Tag ${TAG} créé localement"
echo "💡 Pour push vers GitHub: git push origin ${TAG}"
```

**Note :** Ajoutez `.git/tag-created` au `.gitignore` pour ne pas le commiter.

---

## ✅ Solution 3 : Script Uniquement pour Archive (Meilleure)

La meilleure approche est de s'assurer que le script ne s'exécute QUE lors des archives.

### Configuration Xcode :

1. **Sélectionner** votre "Run Script Phase"
2. **Cocher** : ✅ **"Run script only when installing"**
3. **Décocher** : ❌ **"Based on dependency analysis"**

### Code du Script :

```bash
# Auto-tag version - Uniquement lors d'un Archive Release
if [ "${CONFIGURATION}" != "Release" ]; then
    exit 0
fi

# Récupérer la version depuis Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${PROJECT_DIR}/Configs/Info.plist")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${PROJECT_DIR}/Configs/Info.plist")
TAG="v${VERSION}"

echo "🏷️  Création du tag ${TAG}..."

# Vérifier si on est dans un dépôt Git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "⚠️  Pas un dépôt Git. Skip."
    exit 0
fi

# Vérifier si le tag existe déjà
if git rev-parse "${TAG}" >/dev/null 2>&1; then
    echo "ℹ️  Tag ${TAG} existe déjà. Skip."
    exit 0
fi

# Créer le tag
cd "${SRCROOT}"
git tag -a "${TAG}" -m "Version ${VERSION} (Build ${BUILD_NUMBER}) - Auto-tagged from Xcode"

echo "✅ Tag ${TAG} créé localement"
echo "💡 Pour push vers GitHub: git push origin ${TAG}"
```

---

## 📋 Configuration Recommandée

### Build Phases → Run Script :

```
Shell: /bin/sh
Show environment variables in build log: ✅
Run script only when installing: ✅ (IMPORTANT - uniquement Archive)
Based on dependency analysis: ❌ (DÉCOCHER)
```

### Comportement :

- ✅ **Build Debug** : Script ne s'exécute PAS
- ✅ **Build Release** : Script ne s'exécute PAS
- ✅ **Archive Release** : Script s'exécute ✅
- ✅ **Aucun avertissement** : Plus d'avertissement Xcode

---

## 🎯 Résumé

**Action à faire :**
1. Ouvrir Xcode → Build Phases → Votre Run Script
2. **Décocher** "Based on dependency analysis" ❌
3. **Cocher** "Run script only when installing" ✅

**Résultat :** 
- ✅ Avertissement disparu
- ✅ Script s'exécute uniquement lors des archives
- ✅ Pas d'impact sur les builds normaux

---

**C'est la solution la plus simple et la plus efficace ! ✅**

