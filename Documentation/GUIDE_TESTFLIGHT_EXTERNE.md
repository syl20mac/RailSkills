# 🚀 Guide pour Déposer RailSkills sur TestFlight Externe

**Date :** 3 décembre 2025  
**Plateforme :** iPadOS 18.6+ (TestFlight externe)

---

## 📋 Checklist Complète pour TestFlight

### ✅ 1. Bundle Identifier Valide

**État actuel :**
- Bundle ID : `com.railskills.syl20.org.RailSkills`
- ⚠️ **IMPORTANT** : Vérifier que ce bundle ID est enregistré dans App Store Connect

**Action requise :**
1. Aller sur [App Store Connect](https://appstoreconnect.apple.com)
2. Créer une nouvelle app avec ce bundle identifier
3. OU utiliser un bundle ID déjà créé

---

### ✅ 2. Version et Build Number

**Configuration actuelle :**
- Version : `1.0` (MARKETING_VERSION)
- Build : `1` (CURRENT_PROJECT_VERSION)

**Modifications nécessaires pour chaque build TestFlight :**
- ⚠️ **Incrémenter le Build Number** à chaque upload (1, 2, 3, ...)
- Version peut rester `1.0` pour les builds de test

**Fichiers à modifier :**
- `project.pbxproj` : `CURRENT_PROJECT_VERSION`
- `Configs/Info.plist` : `CFBundleVersion`

---

### ✅ 3. Configuration de Production

**Vérifier :**
- [x] Configuration Release configurée
- [x] Bundle identifier défini
- [ ] Certificat de distribution configuré
- [ ] Provisioning profile valide

---

### ✅ 4. Signing & Capabilities

**Vérifications nécessaires :**

#### Dans Xcode :
1. **Sélectionner le projet** → Cible "RailSkills"
2. **Onglet "Signing & Capabilities"**
3. Vérifier :
   - ✅ Team sélectionné : `UD44R8K7U8` (Sylvain GALLON)
   - ✅ Bundle Identifier : `com.railskills.syl20.org.RailSkills`
   - ✅ Automatically manage signing : Activé
   - ✅ Distribution certificate : Valide

---

### ✅ 5. Privacy Descriptions (Obligatoire)

**Vérifier dans Info.plist :**

#### Descriptions de confidentialité requises :
- ✅ `NSSpeechRecognitionUsageDescription` : Présent
- ✅ `NSMicrophoneUsageDescription` : Présent

#### Descriptions manquantes possibles :
- [ ] `NSPhotoLibraryUsageDescription` (si utilisation de photos)
- [ ] `NSLocationWhenInUseUsageDescription` (si géolocalisation)
- [ ] `NSCameraUsageDescription` (si caméra utilisée)

**Note :** Votre app n'utilise pas ces fonctionnalités, donc c'est OK.

---

### ✅ 6. App Icon

**Vérifier :**
- [ ] Toutes les tailles d'icône présentes
- [ ] Format PNG valide
- [ ] Pas de transparence (pour App Store)
- [ ] Couleurs conformes

**Localisation :**
- `Assets.xcassets/AppIcon.appiconset/`

---

### ✅ 7. Launch Screen

**Vérifier :**
- [ ] Launch screen configuré dans Info.plist
- [ ] Affichage correct au démarrage

**État actuel :**
- ✅ `UILaunchScreen` présent dans Info.plist

---

### ✅ 8. Sécurité et Secrets

**Vérifications critiques :**
- [ ] Aucun secret hardcodé dans le code
- [ ] Secrets dans fichiers de configuration non versionnés
- [ ] Pas de tokens dans les logs
- [ ] Backend configuré pour production

---

### ✅ 9. Configuration iOS 18

**Vérifier :**
- ✅ Deployment target : iOS 18.0
- ✅ Compatible avec iPadOS 18.6+
- ✅ Pas de vérifications iOS 17 à supprimer

---

### ✅ 10. App Store Connect

**Informations requises :**
1. **Nom de l'app** : RailSkills
2. **Catégorie principale** : Productivity (ou Business)
3. **Description** : À préparer
4. **Mots-clés** : À définir
5. **Captures d'écran** : iPad requis
6. **Politique de confidentialité** : URL requise pour TestFlight externe
7. **Notes de version** : À rédiger

---

## 🔧 Modifications Nécessaires

### 1. Incrémenter le Build Number

**Avant chaque upload TestFlight :**

```swift
// Dans project.pbxproj
CURRENT_PROJECT_VERSION = 2; // Incrémenter à chaque fois

// Dans Info.plist
<key>CFBundleVersion</key>
<string>2</string> // Incrémenter à chaque fois
```

### 2. Vérifier le Bundle Identifier

**Dans App Store Connect :**
- Le bundle ID doit être enregistré
- Vérifier qu'il n'est pas déjà utilisé par une autre app

### 3. Configuration Production

**Utiliser la configuration Release :**
- Scheme : **RailSkills → Release**
- Archive avec cette configuration

---

## 📝 Checklist Avant Upload

### Configuration
- [ ] Bundle identifier enregistré dans App Store Connect
- [ ] Build number incrémenté
- [ ] Version définie correctement
- [ ] Configuration Release sélectionnée

### Signing
- [ ] Team configuré correctement
- [ ] Certificat de distribution valide
- [ ] Provisioning profile valide
- [ ] Automatically manage signing activé

### Contenu
- [ ] App icon complet et valide
- [ ] Launch screen configuré
- [ ] Privacy descriptions complètes
- [ ] Pas de secrets hardcodés

### TestFlight
- [ ] App créée dans App Store Connect
- [ ] Description préparée
- [ ] Notes de version rédigées
- [ ] Politique de confidentialité URL disponible
- [ ] Captures d'écran préparées (si première version)

---

## 🚀 Procédure d'Upload

### Étape 1 : Préparer l'Archive

1. **Ouvrir Xcode**
2. **Sélectionner le scheme** : RailSkills
3. **Sélectionner "Any iOS Device"** ou un appareil générique
4. **Product → Archive** (⇧⌘B)
5. **Attendre la fin de l'archive**

### Étape 2 : Valider l'Archive

1. **Organizer s'ouvre automatiquement** (Window → Organizer)
2. **Sélectionner l'archive**
3. **Cliquer sur "Validate App"**
4. **Suivre le processus de validation**
5. **Corriger les erreurs éventuelles**

### Étape 3 : Distribuer vers App Store Connect

1. **Dans Organizer, sélectionner l'archive**
2. **Cliquer sur "Distribute App"**
3. **Choisir "App Store Connect"**
4. **Suivre l'assistant :**
   - Upload
   - Automatically manage signing (si activé)
   - Distribuer
5. **Attendre la fin de l'upload**

### Étape 4 : Configurer dans App Store Connect

1. **Aller sur App Store Connect**
2. **My Apps → RailSkills**
3. **TestFlight**
4. **Ajouter les informations :**
   - Notes de version
   - Description
   - Politique de confidentialité (URL)
5. **Soumettre pour révision TestFlight externe**

---

## ⚠️ Points d'Attention

### Bundle Identifier

**Format requis :**
- Format reverse-DNS valide
- Exemple : `com.railskills.syl20.org.RailSkills`
- Ne peut pas être changé après création dans App Store Connect

### Build Number

- ⚠️ **Doit être incrémenté** à chaque upload
- Format : Entier croissant (1, 2, 3, ...)
- Ne peut pas être réutilisé

### Certificats

- ✅ Certificat de distribution requis
- ✅ Provisioning profile App Store
- ✅ Valide et non expiré

### Politique de Confidentialité

**Obligatoire pour TestFlight externe :**
- URL publique accessible
- Contenu en français
- Décrit l'utilisation des données

---

## 📚 Checklist Finale

### Avant Archive
- [ ] Build number incrémenté
- [ ] Version définie
- [ ] Configuration Release
- [ ] Secrets retirés du code
- [ ] Tests effectués

### Avant Upload
- [ ] Archive créée
- [ ] Archive validée
- [ ] Aucune erreur de validation

### Dans App Store Connect
- [ ] App créée avec bundle ID
- [ ] Informations complétées
- [ ] Notes de version rédigées
- [ ] Politique de confidentialité URL fournie

---

**Votre app est presque prête pour TestFlight ! 🚀**









