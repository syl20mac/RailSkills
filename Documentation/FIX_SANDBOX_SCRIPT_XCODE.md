# 🔒 Résoudre l'Erreur Sandbox Xcode

**Erreur :** `Sandbox: bash(24305) deny(1) file-read-data`

Cette erreur se produit car macOS bloque l'accès au script pour des raisons de sécurité.

---

## ✅ Solution 1 : Utiliser le Script Inline (Recommandé)

Au lieu d'appeler un script externe, mettez le code directement dans Xcode.

### Dans Xcode Build Phases :

1. **Ouvrir Xcode**
2. **Projet** → **Target "RailSkills"** → **Build Phases**
3. **Sélectionner votre "Run Script Phase"**
4. **Remplacer** l'appel au script par le code inline :

```bash
# Auto-tag version lors d'un build Release
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

echo "✅ Tag ${TAG} créé localement"
echo "💡 Pour push vers GitHub: git push origin ${TAG}"
```

---

## ✅ Solution 2 : Désactiver App Sandbox (Si Nécessaire)

Si vous devez absolument utiliser un script externe :

### Option A : Utiliser le chemin absolu

```bash
# Dans Xcode Build Phases, utiliser le chemin absolu
/Users/sylvaingallon/Desktop/Railskills\ rebuild/RailSkills/scripts/auto-tag-version.sh
```

### Option B : Copier le script dans le bundle

1. **Ajouter le script au projet Xcode**
2. **Cocher** : "Copy Bundle Resources" (dans Build Phases)
3. **Utiliser** : `${SRCROOT}/scripts/auto-tag-version.sh`

---

## ✅ Solution 3 : Utiliser un Script Post-Archive (Recommandé)

Au lieu d'utiliser Build Phases, utilisez un script post-archive.

### Créer un script post-archive :

1. **Créer** : `scripts/post-archive-tag.sh`

```bash
#!/bin/bash
# Script exécuté après l'archive

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${1}/Products/Applications/RailSkills.app/Contents/Info.plist")
TAG="v${VERSION}"

cd "${SRCROOT}"
git tag -a "${TAG}" -m "Version ${VERSION} - Archive"
git push origin "${TAG}"
```

2. **Dans Xcode** → **Product** → **Scheme** → **Edit Scheme**
3. **Archive** → **Post-actions**
4. **+** → **New Run Script Action**
5. **Coller le code du script**

---

## ✅ Solution 4 : Script Manuel (Plus Simple)

Au lieu d'automatiser dans Xcode, créez un script à exécuter manuellement après l'archive.

### Créer `scripts/tag-release.sh` :

```bash
#!/bin/bash

cd "$(dirname "$0")/.."

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "Configs/Info.plist")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "Configs/Info.plist")

TAG="v${VERSION}"
TAG_MESSAGE="Version ${VERSION} (Build ${BUILD_NUMBER})"

echo "🏷️  Création du tag ${TAG}..."

if git rev-parse "${TAG}" >/dev/null 2>&1; then
    echo "⚠️  Le tag ${TAG} existe déjà."
    read -p "Voulez-vous le supprimer et le recréer ? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git tag -d "${TAG}"
        git push origin ":refs/tags/${TAG}" 2>/dev/null || true
    else
        exit 0
    fi
fi

git tag -a "${TAG}" -m "${TAG_MESSAGE}"
git push origin "${TAG}"

echo "✅ Tag ${TAG} créé et pushé vers GitHub"
echo "📦 Créez maintenant la release sur: https://github.com/syl20mac/RailSkills/releases/new"
```

### Utilisation :

```bash
cd "/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills"
./scripts/tag-release.sh
```

---

## 🎯 Recommandation

**Utilisez la Solution 1 (Script Inline)** - C'est la plus simple et évite tous les problèmes de sandbox.

Le code est directement dans Xcode, donc pas de problème de permissions.

---

## 📝 Configuration Xcode Recommandée

### Build Phases → Run Script :

```
Shell: /bin/sh
Show environment variables in build log: ✅
Run script only when installing: ✅ (uniquement pour Archive)
Based on dependency analysis: ❌ (DÉCOCHER pour éviter l'avertissement)
```

**Important :** Décocher "Based on dependency analysis" pour éviter l'avertissement Xcode.

### Code du Script (inline) :

```bash
# Auto-tag version lors d'un build Release Archive
if [ "${CONFIGURATION}" != "Release" ]; then
    exit 0
fi

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${PROJECT_DIR}/Configs/Info.plist")
BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${PROJECT_DIR}/Configs/Info.plist")
TAG="v${VERSION}"

if git rev-parse "${TAG}" >/dev/null 2>&1; then
    echo "ℹ️  Tag ${TAG} existe déjà"
    exit 0
fi

cd "${SRCROOT}"
git tag -a "${TAG}" -m "Version ${VERSION} (Build ${BUILD_NUMBER})"
echo "✅ Tag ${TAG} créé. Push avec: git push origin ${TAG}"
```

---

**Cette solution évite complètement les problèmes de sandbox ! ✅**





















