# 📝 Modifications Nécessaires pour TestFlight Externe

**Date :** 3 décembre 2025  
**Objectif :** Préparer RailSkills pour TestFlight externe

---

## ⚠️ Modifications Obligatoires

### 1. 🔢 Incrémenter le Build Number

**Action requise AVANT chaque upload TestFlight :**

**Fichier :** `RailSkills.xcodeproj/project.pbxproj`

**Changer :**
```swift
CURRENT_PROJECT_VERSION = 1;  // Actuel
```

**En :**
```swift
CURRENT_PROJECT_VERSION = 2;  // Incrémenter à chaque upload
```

**ET dans :** `Configs/Info.plist`

```xml
<key>CFBundleVersion</key>
<string>2</string>  <!-- Incrémenter aussi ici -->
```

**⚠️ IMPORTANT :** Le build number doit être **unique et croissant** à chaque upload.

---

### 2. 🆔 Bundle Identifier dans App Store Connect

**Vérifier :**
- Bundle ID actuel : `com.railskills.syl20.org.RailSkills`
- ⚠️ Ce bundle ID **DOIT être créé dans App Store Connect** avant l'upload

**Actions :**
1. Aller sur [App Store Connect](https://appstoreconnect.apple.com)
2. My Apps → "+" → New App
3. Informations requises :
   - **Platform** : iOS
   - **Name** : RailSkills
   - **Primary Language** : French
   - **Bundle ID** : `com.railskills.syl20.org.RailSkills` (sélectionner ou créer)
   - **SKU** : `RailSkills-iOS-001` (unique identifier)

---

### 3. 📱 Privacy Policy URL (Obligatoire pour TestFlight Externe)

**Obligatoire pour TestFlight externe :**

Vous devez avoir une URL publique vers votre politique de confidentialité :
- Exemple : `https://votresite.com/privacy-policy`
- Doit être accessible publiquement
- En français
- Décrit l'utilisation des données

**À ajouter dans App Store Connect :**
- My Apps → RailSkills → App Information
- Privacy Policy URL : [votre URL]

---

### 4. 📸 Captures d'écran (Première version uniquement)

**Pour la première soumission TestFlight externe :**
- Capture d'écran iPad requise
- Format : Au moins 1024x768 pixels
- Maximum 5 captures d'écran

**⚠️ Pour TestFlight interne, pas obligatoire, mais recommandé.**

---

### 5. ✅ Vérifications de Sécurité

**À vérifier AVANT upload :**

- [ ] Aucun secret hardcodé dans le code
- [ ] Pas de tokens dans les logs
- [ ] Backend configuré pour production
- [ ] Secrets dans fichiers de configuration non versionnés

---

## 🔧 Modifications Recommandées

### 1. Notes de Version pour TestFlight

**À préparer pour chaque build :**
- Description des nouveautés
- Corrections de bugs
- Instructions pour les testeurs

**Exemple :**
```
Version 1.0 (Build 2)

Nouveautés :
- Améliorations iOS 18 avec design moderne
- Composants modernisés avec animations fluides
- Haptic feedback amélioré

Corrections :
- Correction du bundle identifier
- Amélioration des performances

Instructions :
- Tester sur iPadOS 18.6+
- Vérifier la synchronisation SharePoint
```

---

### 2. Description de l'App (TestFlight)

**À préparer :**

```
RailSkills est une application iPad pour la SNCF permettant aux CTT 
(Cadres Transport Traction) et ARC (Adjoints Référents Conduite) de 
gérer le suivi triennal réglementaire des conducteurs circulant au 
Luxembourg.

Fonctionnalités :
- Suivi des évaluations triennales
- Checklist CFL avec 46 points de contrôle
- Synchronisation SharePoint
- Génération de rapports PDF
- Export/Import de données
```

---

## 📋 Checklist Complète

### Configuration Xcode
- [ ] Bundle identifier défini : `com.railskills.syl20.org.RailSkills`
- [ ] Build number incrémenté (1, 2, 3, ...)
- [ ] Version définie (1.0)
- [ ] Configuration Release utilisée
- [ ] Team configuré : `UD44R8K7U8`
- [ ] Signing automatique activé

### App Store Connect
- [ ] App créée avec le bundle ID
- [ ] Informations de base complétées
- [ ] Privacy Policy URL fournie
- [ ] Notes de version rédigées
- [ ] Description préparée

### Code & Sécurité
- [ ] Aucun secret hardcodé
- [ ] Privacy descriptions complètes dans Info.plist
- [ ] App icon complet
- [ ] Tests effectués sur iPad réel

### Archive & Upload
- [ ] Archive créée avec configuration Release
- [ ] Archive validée sans erreur
- [ ] Upload vers App Store Connect réussi
- [ ] Build traité par Apple

---

## 🚀 Procédure Complète

### Étape 1 : Préparer dans Xcode

1. **Incrémenter le build number :**
   - Ouvrir `project.pbxproj`
   - Chercher `CURRENT_PROJECT_VERSION`
   - Incrémenter la valeur
   - Mettre à jour aussi dans `Info.plist` (`CFBundleVersion`)

2. **Vérifier la configuration :**
   - Scheme : RailSkills
   - Configuration : Release
   - Team : UD44R8K7U8

### Étape 2 : Créer l'Archive

1. **Product → Clean Build Folder** (⇧⌘K)
2. **Sélectionner "Any iOS Device"**
3. **Product → Archive** (⇧⌘B)
4. **Attendre la fin**

### Étape 3 : Valider

1. **Window → Organizer**
2. **Sélectionner l'archive**
3. **Validate App**
4. **Corriger les erreurs si nécessaire**

### Étape 4 : Distribuer

1. **Distribute App**
2. **App Store Connect**
3. **Upload**
4. **Attendre la fin**

### Étape 5 : Configurer dans App Store Connect

1. **My Apps → RailSkills → TestFlight**
2. **Ajouter les informations :**
   - Notes de version
   - Privacy Policy URL
3. **Soumettre pour révision TestFlight externe**

---

## ⚠️ Points Critiques

### Bundle Identifier
- ⚠️ **Ne peut pas être changé** après création
- Doit être **unique** dans votre compte
- Format reverse-DNS requis

### Build Number
- ⚠️ **Doit être incrémenté** à chaque upload
- Ne peut pas réutiliser un build number précédent
- Format entier croissant

### Privacy Policy
- ⚠️ **Obligatoire pour TestFlight externe**
- URL publique requise
- En français recommandé
- Doit décrire l'utilisation des données

---

## 📊 État Actuel de Votre App

### ✅ Déjà Configuré
- ✅ Bundle identifier : `com.railskills.syl20.org.RailSkills`
- ✅ Version : 1.0
- ✅ Build : 1
- ✅ Privacy descriptions dans Info.plist
- ✅ App icon présent
- ✅ Launch screen configuré
- ✅ Deployment target : iOS 18.0

### ⚠️ À Faire
- [ ] Incrémenter build number à chaque upload
- [ ] Créer l'app dans App Store Connect
- [ ] Préparer Privacy Policy URL
- [ ] Rédiger notes de version
- [ ] Configurer le certificat de distribution

---

## 🎯 Actions Immédiates

### 1. Avant Premier Upload

1. ✅ Vérifier bundle ID dans App Store Connect
2. ✅ Incrémenter build number (si pas encore fait)
3. ✅ Préparer Privacy Policy URL
4. ✅ Créer l'archive Release

### 2. Après Upload

1. ✅ Ajouter notes de version dans App Store Connect
2. ✅ Fournir Privacy Policy URL
3. ✅ Soumettre pour révision TestFlight externe

---

**Votre app est presque prête ! Il reste principalement à incrémenter le build number et créer l'app dans App Store Connect. 🚀**








