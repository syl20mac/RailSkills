# Guide - Créer et Indexer des Releases GitHub

**Objectif :** Créer des releases GitHub pour que vos versions soient indexées et visibles.

---

## 🎯 Pourquoi Créer des Releases GitHub ?

- ✅ **Indexation** : Les releases sont indexées par les moteurs de recherche
- ✅ **Visibilité** : Facilement trouvables sur la page GitHub du projet
- ✅ **Téléchargements** : Permet de distribuer des fichiers (IPA, etc.)
- ✅ **Notes de version** : Documenter les changements par version
- ✅ **Tags Git** : Marquer les versions importantes dans l'historique

---

## 📋 Méthode 1 : Via l'Interface GitHub (Recommandé)

### Étape 1 : Créer un Tag Git

Dans votre terminal, dans le dossier du projet :

```bash
cd "/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills"

# Créer un tag pour la version actuelle (1.2)
git tag -a v1.2 -m "Version 1.2 - Ajout des onglets VP et TE"

# Push le tag vers GitHub
git push origin v1.2
```

**Format des tags :**
- `v1.2` - Version simple
- `v1.2.0` - Version avec patch
- `v1.2.0-beta` - Version beta

### Étape 2 : Créer la Release sur GitHub

1. **Allez sur GitHub :**
   - https://github.com/syl20mac/RailSkills/releases
   - OU : https://github.com/syl20mac/RailSkills → "Releases" (à droite)

2. **Cliquez sur "Draft a new release"**

3. **Remplissez les informations :**
   - **Choose a tag** : Sélectionnez `v1.2` (ou créez-en un nouveau)
   - **Release title** : `Version 1.2 - VP et TE`
   - **Description** : Notes de version détaillées (voir exemple ci-dessous)
   - **Set as the latest release** : ✅ Cocher

4. **Ajouter des fichiers** (optionnel) :
   - Vous pouvez attacher des fichiers (IPA, documentation, etc.)
   - Glissez-déposez ou cliquez "Attach binaries"

5. **Cliquez sur "Publish release"**

---

## 📝 Exemple de Notes de Version

```markdown
## 🎉 Version 1.2 - VP et TE

### ✨ Nouveautés

- **Onglets VP et TE** : Ajout de deux nouveaux onglets de suivi
  - VP (Visite Périodique) avec sa propre checklist
  - TE (Test d'Évaluation) avec sa propre checklist
- **Synchronisation SharePoint** : Support de la synchronisation pour les checklists VP et TE
- **Améliorations UI** : Interface utilisateur améliorée

### 🐛 Corrections

- Corrections de bugs divers
- Améliorations de performance

### 📱 Compatibilité

- iOS 18.0+
- iPadOS 18.0+
- Support iPad et iPhone

### 📄 Documentation

- Privacy Policy : https://syl20mac.github.io/RailSkills-Public/PRIVACY_POLICY.html
- Support : https://syl20mac.github.io/RailSkills-Public/SUPPORT.html

---

**Date de release :** 11 décembre 2025
```

---

## 📋 Méthode 2 : Via la Ligne de Commande

### Créer un Tag et Push

```bash
# Se placer dans le dossier du projet
cd "/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills"

# Créer un tag annoté (avec message)
git tag -a v1.2 -m "Version 1.2 - Ajout des onglets VP et TE"

# Push le tag vers GitHub
git push origin v1.2

# OU push tous les tags
git push --tags
```

### Créer la Release via GitHub CLI (si installé)

```bash
# Installer GitHub CLI si pas déjà fait
# brew install gh

# Se connecter
gh auth login

# Créer une release
gh release create v1.2 \
  --title "Version 1.2 - VP et TE" \
  --notes-file CHANGELOG.md \
  --target main
```

---

## 🏷️ Convention de Nommage des Tags

### Format Recommandé

- **Version majeure** : `v1.0`, `v2.0`
- **Version mineure** : `v1.1`, `v1.2`
- **Version patch** : `v1.2.1`, `v1.2.2`
- **Pre-release** : `v1.2.0-beta`, `v1.2.0-rc1`

### Exemples

```bash
# Version majeure
git tag -a v1.0 -m "Version 1.0 - Release initiale"

# Version mineure
git tag -a v1.2 -m "Version 1.2 - Ajout VP et TE"

# Version patch
git tag -a v1.2.1 -m "Version 1.2.1 - Corrections de bugs"

# Pre-release
git tag -a v1.3.0-beta -m "Version 1.3.0 Beta - Tests"
```

---

## 📊 Créer un CHANGELOG.md

Pour automatiser les notes de version, créez un fichier `CHANGELOG.md` :

```markdown
# Changelog

Tous les changements notables de ce projet seront documentés dans ce fichier.

## [1.2] - 2025-12-11

### Ajouté
- Onglets VP (Visite Périodique) et TE (Test d'Évaluation)
- Support de 3 checklists indépendantes
- Synchronisation SharePoint pour VP et TE

### Modifié
- Améliorations de l'interface utilisateur
- Optimisations de performance

### Corrigé
- Corrections de bugs divers

## [1.1] - 2025-XX-XX

### Ajouté
- Mode démonstration pour reviewers Apple
- ...

## [1.0] - 2025-XX-XX

### Ajouté
- Version initiale
- ...
```

---

## 🔍 Vérifier que les Releases sont Indexées

### 1. Vérifier sur GitHub

- Allez sur : https://github.com/syl20mac/RailSkills/releases
- Vous devriez voir toutes vos releases listées

### 2. Vérifier l'Indexation Google

- Recherchez : `site:github.com/syl20mac/RailSkills releases`
- Vos releases devraient apparaître dans les résultats

### 3. Vérifier la Visibilité

- Les releases sont automatiquement visibles sur :
  - La page principale du dépôt (section "Releases")
  - La page dédiée `/releases`
  - Les tags Git

---

## 🚀 Actions Immédiates

### Pour Créer votre Première Release

1. **Créer le tag :**
   ```bash
   cd "/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills"
   git tag -a v1.2 -m "Version 1.2 - Ajout des onglets VP et TE"
   git push origin v1.2
   ```

2. **Créer la release sur GitHub :**
   - Allez sur : https://github.com/syl20mac/RailSkills/releases/new
   - Sélectionnez le tag `v1.2`
   - Remplissez les notes de version
   - Publiez

3. **Vérifier :**
   - https://github.com/syl20mac/RailSkills/releases
   - Votre release devrait être visible

---

## 📝 Template de Notes de Version

Copiez-collez ce template pour vos releases :

```markdown
## 🎉 Version X.X

### ✨ Nouveautés
- 

### 🐛 Corrections
- 

### 🔧 Améliorations
- 

### 📱 Compatibilité
- iOS 18.0+
- iPadOS 18.0+

### 📄 Liens
- Privacy Policy : https://syl20mac.github.io/RailSkills-Public/PRIVACY_POLICY.html
- Support : https://syl20mac.github.io/RailSkills-Public/SUPPORT.html

---
**Date :** [DATE]
**Build :** [BUILD_NUMBER]
```

---

## ✅ Checklist

- [ ] Tag Git créé (`v1.2`)
- [ ] Tag pushé vers GitHub
- [ ] Release créée sur GitHub
- [ ] Notes de version rédigées
- [ ] Release publiée
- [ ] Vérification que la release est visible

---

**Une fois publiée, votre release sera automatiquement indexée et visible ! 🚀**

