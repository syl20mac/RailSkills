# Guide - Automatiser les Releases GitHub depuis Xcode

**Objectif :** Automatiser la création de tags Git et releases GitHub lors des builds Xcode.

---

## 🎯 Options d'Automatisation

### Option 1 : Tag Automatique (Simple) ✅ Recommandé

Crée automatiquement un tag Git lors d'un build Release.

### Option 2 : Release Complète (Avancé)

Crée le tag ET la release GitHub via l'API.

---

## 📋 Option 1 : Tag Automatique (Simple)

### Étape 1 : Préparer le Script

Le script `scripts/auto-tag-version.sh` est déjà créé.

### Étape 2 : Ajouter dans Xcode

1. **Ouvrir Xcode**
2. **Sélectionner le projet** dans le navigateur
3. **Sélectionner la target "RailSkills"**
4. **Onglet "Build Phases"**
5. **Cliquer sur "+"** → **"New Run Script Phase"**
6. **Déplacer le script** après "Copy Bundle Resources"
7. **Coller ce code :**

```bash
# Auto-tag version lors d'un build Release
if [ "${CONFIGURATION}" == "Release" ]; then
    "${PROJECT_DIR}/scripts/auto-tag-version.sh"
fi
```

8. **Nommer la phase** : "Auto Tag Version"
9. **Cocher** : "For install builds only" (optionnel)

### Étape 3 : Tester

1. **Changer la configuration** en "Release"
2. **Product → Archive**
3. Le script créera automatiquement le tag `v1.2` (selon la version dans Info.plist)

### Étape 4 : Push le Tag (Manuel)

Après l'archive, push le tag :

```bash
cd "/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills"
git push origin v1.2
```

Puis créez la release manuellement sur GitHub (voir Option 1 du guide précédent).

---

## 📋 Option 2 : Release Complète (Avancé)

### Étape 1 : Créer un Token GitHub

1. **Allez sur** : https://github.com/settings/tokens
2. **Generate new token** → **Generate new token (classic)**
3. **Nom** : `Xcode Release Automation`
4. **Permissions** :
   - ✅ `repo` (Full control of private repositories)
5. **Generate token**
6. **Copier le token** (vous ne le reverrez plus !)

### Étape 2 : Ajouter le Token dans Xcode

#### Méthode A : Variables d'Environnement (Recommandé)

1. **Xcode** → **Product** → **Scheme** → **Edit Scheme**
2. **Run** (ou **Archive**) → **Arguments**
3. **Environment Variables** → **+**
4. **Name** : `GITHUB_TOKEN`
5. **Value** : `[votre token GitHub]`
6. **OK**

#### Méthode B : Fichier de Configuration (Plus Sécurisé)

Créez un fichier `.github_token` (NE PAS COMMITER) :

```bash
# Dans le terminal
cd "/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills"
echo "votre_token_github" > .github_token
chmod 600 .github_token
```

Ajoutez `.github_token` au `.gitignore` :

```bash
echo ".github_token" >> .gitignore
```

Modifiez le script pour lire le token :

```bash
# Dans create-release.sh, remplacer :
GITHUB_TOKEN="${GITHUB_TOKEN}"

# Par :
if [ -f "${PROJECT_DIR}/.github_token" ]; then
    GITHUB_TOKEN=$(cat "${PROJECT_DIR}/.github_token")
fi
```

### Étape 3 : Installer jq (pour JSON)

```bash
# Via Homebrew
brew install jq
```

### Étape 4 : Ajouter le Script dans Xcode

1. **Ouvrir Xcode**
2. **Sélectionner le projet** → **Target "RailSkills"** → **Build Phases**
3. **+** → **New Run Script Phase**
4. **Déplacer** après "Copy Bundle Resources"
5. **Coller :**

```bash
# Auto-create GitHub release lors d'un build Release
if [ "${CONFIGURATION}" == "Release" ]; then
    "${PROJECT_DIR}/scripts/create-release.sh"
fi
```

6. **Nommer** : "Auto Create GitHub Release"

### Étape 5 : Tester

1. **Configuration Release**
2. **Product → Archive**
3. Le script créera automatiquement :
   - Le tag Git
   - La release GitHub

---

## 🔧 Configuration Avancée

### Personnaliser les Notes de Release

Modifiez `scripts/create-release.sh` pour personnaliser les notes :

```bash
RELEASE_NOTES=$(cat <<EOF
## 🎉 Version ${VERSION}

### ✨ Nouveautés
- Votre contenu ici

### 🐛 Corrections
- Corrections diverses
EOF
)
```

### Utiliser un Fichier CHANGELOG.md

Modifiez le script pour lire depuis CHANGELOG.md :

```bash
if [ -f "${PROJECT_DIR}/CHANGELOG.md" ]; then
    # Extraire les notes pour cette version
    RELEASE_NOTES=$(awk "/^## \[${VERSION}\]/,/^## \[/" "${PROJECT_DIR}/CHANGELOG.md" | head -n -1)
else
    RELEASE_NOTES="Version ${VERSION}"
fi
```

### Conditionner sur le Build Number

Pour créer une release uniquement si le build number change :

```bash
LAST_BUILD=$(git describe --tags --match "v*" --abbrev=0 2>/dev/null || echo "")
CURRENT_BUILD="v${VERSION}-b${BUILD_NUMBER}"

if [ "${LAST_BUILD}" != "${CURRENT_BUILD}" ]; then
    # Créer la release
fi
```

---

## 📝 Scripts Disponibles

### 1. `scripts/auto-tag-version.sh`
- ✅ Simple
- ✅ Crée uniquement le tag Git
- ✅ Pas de dépendances
- ✅ Recommandé pour commencer

### 2. `scripts/create-release.sh`
- ✅ Complet
- ✅ Crée tag + release GitHub
- ⚠️ Nécessite GITHUB_TOKEN
- ⚠️ Nécessite jq (pour JSON)

---

## ✅ Checklist

### Pour Option 1 (Simple)
- [ ] Script `auto-tag-version.sh` créé
- [ ] Script ajouté dans Xcode Build Phases
- [ ] Testé avec un build Release
- [ ] Tag créé localement
- [ ] Tag pushé vers GitHub (manuel)
- [ ] Release créée sur GitHub (manuel)

### Pour Option 2 (Avancé)
- [ ] Token GitHub créé
- [ ] Token configuré dans Xcode (ou fichier .github_token)
- [ ] jq installé (`brew install jq`)
- [ ] Script `create-release.sh` créé
- [ ] Script ajouté dans Xcode Build Phases
- [ ] Testé avec un build Release
- [ ] Tag et release créés automatiquement

---

## 🚀 Workflow Recommandé

### Workflow Simple (Option 1)

1. **Développement** → Build Debug (pas de tag)
2. **Test** → Build Release (tag créé automatiquement)
3. **Archive** → Tag pushé manuellement
4. **Release** → Créée manuellement sur GitHub

### Workflow Automatique (Option 2)

1. **Développement** → Build Debug (pas de release)
2. **Archive Release** → Tag + Release créés automatiquement
3. **Vérification** → Release visible sur GitHub

---

## 🔒 Sécurité

### ⚠️ Important

- **Ne JAMAIS commiter** le token GitHub dans le dépôt
- Utiliser `.gitignore` pour exclure `.github_token`
- Utiliser les variables d'environnement Xcode (plus sécurisé)
- Limiter les permissions du token (uniquement `repo`)

---

## 📊 Exemple de Configuration Xcode

### Build Phases Order

1. Target Dependencies
2. Compile Sources
3. Link Binary With Libraries
4. Copy Bundle Resources
5. **Auto Tag Version** ← Votre script ici
6. **Auto Create GitHub Release** ← Ou celui-ci

### Script Configuration

```
Shell: /bin/sh
Show environment variables in build log: ✅ (pour debug)
Run script only when installing: ✅ (optionnel - uniquement pour Archive)
```

---

## 🐛 Dépannage

### Le tag n'est pas créé

- Vérifier que la configuration est "Release"
- Vérifier les logs Xcode (View → Navigators → Show Report)
- Vérifier les permissions d'exécution : `chmod +x scripts/auto-tag-version.sh`

### La release n'est pas créée

- Vérifier que GITHUB_TOKEN est défini
- Vérifier que jq est installé : `which jq`
- Vérifier les logs Xcode pour les erreurs API

### Erreur "git command not found"

- Vérifier que Git est dans le PATH
- Ajouter dans le script : `export PATH="/usr/bin:/usr/local/bin:$PATH"`

---

**Une fois configuré, vos releases seront créées automatiquement lors des archives ! 🚀**

