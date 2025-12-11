# 🚀 Guide Xcode - Configuration TestFlight Externe

**Date :** 4 décembre 2025  
**Application :** RailSkills iOS  
**Objectif :** Configurer Xcode et soumettre l'app pour TestFlight externe

---

## 📋 Prérequis

Avant de commencer, assurez-vous d'avoir :

- ✅ Compte développeur Apple actif (Apple Developer Program - 99€/an)
- ✅ Xcode installé (dernière version recommandée)
- ✅ Accès à [App Store Connect](https://appstoreconnect.apple.com)
- ✅ Bundle ID enregistré : `com.railskills.syl20.org.RailSkills`
- ✅ Team configuré dans Xcode : `UD44R8K7U8` (Sylvain GALLON)

---

## 🔧 ÉTAPE 1 : Vérifier la Configuration du Projet

### 1.1 Ouvrir le Projet dans Xcode

1. **Ouvrir Xcode**
2. **File → Open** → Sélectionner `RailSkills.xcodeproj`
3. **Attendre** que le projet se charge complètement

### 1.2 Vérifier les Paramètres du Projet

1. **Sélectionner le projet** dans le navigateur (icône bleue en haut)
2. **Sélectionner la cible "RailSkills"** (pas le projet)
3. **Onglet "General"** :

   **Vérifier :**
   - ✅ **Display Name** : RailSkills
   - ✅ **Bundle Identifier** : `com.railskills.syl20.org.RailSkills`
   - ✅ **Version** : `1.0` (MARKETING_VERSION)
   - ✅ **Build** : `2` ou supérieur (CURRENT_PROJECT_VERSION)
   - ✅ **Minimum Deployments** : iOS 18.0

### 1.3 Vérifier le Signing & Capabilities

1. **Onglet "Signing & Capabilities"**

   **Vérifier :**
   - ✅ **Team** : `Sylvain GALLON (UD44R8K7U8)`
   - ✅ **Bundle Identifier** : `com.railskills.syl20.org.RailSkills`
   - ✅ **Automatically manage signing** : **COCHÉ** ✅
   - ✅ **Provisioning Profile** : App Store (généré automatiquement)

   **Si erreur de provisioning :**
   - Cliquer sur "Download Manual Profiles"
   - Ou laisser Xcode gérer automatiquement

---

## 🔢 ÉTAPE 2 : Incrémenter le Build Number (OBLIGATOIRE)

⚠️ **À faire AVANT chaque upload TestFlight !**

### Option A : Via l'Interface Xcode (Recommandé)

1. **Sélectionner le projet** → Cible "RailSkills"
2. **Onglet "General"**
3. **Section "Identity"**
4. **Build** : Incrémenter (ex: `2` → `3`)
5. **Appuyer sur Entrée** pour valider

### Option B : Via les Fichiers (Si nécessaire)

**Fichier 1 : `RailSkills.xcodeproj/project.pbxproj`**

Chercher et modifier :
```bash
CURRENT_PROJECT_VERSION = 2;  # Incrémenter à 3, 4, etc.
```

**Fichier 2 : `Configs/Info.plist`**

Chercher et modifier :
```xml
<key>CFBundleVersion</key>
<string>2</string>  <!-- Incrémenter à 3, 4, etc. -->
```

---

## 🏗️ ÉTAPE 3 : Configurer le Scheme pour Release

1. **En haut de Xcode**, à côté du bouton Play
2. **Cliquer sur le scheme** (ex: "RailSkills > iPhone 15 Pro")
3. **Edit Scheme...**
4. **Onglet "Archive"** (à gauche)
5. **Configuration** : Sélectionner **"Release"**
6. **Close**

---

## 📦 ÉTAPE 4 : Créer l'Archive

### 4.1 Nettoyer le Build

1. **Product → Clean Build Folder** (⇧⌘K)
2. **Attendre** la fin du nettoyage

### 4.2 Sélectionner la Destination

1. **En haut de Xcode**, à côté du scheme
2. **Cliquer sur la destination** (ex: "iPhone 15 Pro")
3. **Sélectionner "Any iOS Device"** (pas un simulateur !)

   ⚠️ **Important** : Si "Any iOS Device" n'apparaît pas :
   - Vérifier que le projet compile sans erreur
   - Vérifier le signing dans "Signing & Capabilities"

### 4.3 Créer l'Archive

1. **Product → Archive** (⇧⌘B)
2. **Attendre** la fin de l'archive (peut prendre plusieurs minutes)
3. **L'Organizer s'ouvre automatiquement** à la fin

---

## ✅ ÉTAPE 5 : Valider l'Archive

1. **Dans l'Organizer** (Window → Organizer si fermé)
2. **Sélectionner l'archive** la plus récente
3. **Cliquer sur "Validate App"**
4. **Suivre l'assistant** :
   - **Distribution** : App Store Connect
   - **Automatically manage signing** : Cocher ✅
   - **Valider**
5. **Attendre** la validation (peut prendre 2-5 minutes)
6. **Vérifier les résultats** :
   - ✅ **Succès** : Passer à l'étape 6
   - ❌ **Erreurs** : Corriger et recommencer depuis l'étape 4

---

## 📤 ÉTAPE 6 : Uploader vers App Store Connect

1. **Dans l'Organizer**, sélectionner l'archive validée
2. **Cliquer sur "Distribute App"**
3. **Choisir "App Store Connect"** → Next
4. **Choisir "Upload"** → Next
5. **Options de distribution** :
   - ✅ **Automatically manage signing** : Cocher
   - ✅ **Include bitcode** : Cocher (si disponible)
   - ✅ **Upload symbols** : Cocher
   - Next
6. **Révision** : Vérifier les informations
7. **Distribute** : Cliquer pour lancer l'upload
8. **Attendre** la fin de l'upload (peut prendre 5-15 minutes)

   ✅ **Message de succès** : "Upload réussi"

---

## 🌐 ÉTAPE 7 : Configurer dans App Store Connect

### 7.1 Accéder à App Store Connect

1. **Aller sur** [https://appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. **Se connecter** avec votre compte développeur
3. **My Apps** → Sélectionner **"RailSkills"**

   ⚠️ **Si l'app n'existe pas encore** :
   - Cliquer sur **"+"** → **"New App"**
   - Remplir :
     - **Platform** : iOS
     - **Name** : RailSkills
     - **Primary Language** : French
     - **Bundle ID** : `com.railskills.syl20.org.RailSkills`
     - **SKU** : `RailSkills-iOS-001`
   - **Create**

### 7.2 Vérifier le Build Uploadé

1. **Onglet "TestFlight"** (à gauche)
2. **Section "iOS Builds"**
3. **Attendre** que le build apparaisse (peut prendre 10-30 minutes)
4. **Statut** :
   - ⏳ **Processing** : En cours de traitement
   - ✅ **Ready to Submit** : Prêt à configurer
   - ❌ **Invalid Binary** : Vérifier les erreurs

### 7.3 Configurer les Informations TestFlight

Une fois le build **"Ready to Submit"** :

1. **Cliquer sur le build**
2. **Remplir les informations** :

   **a) Notes de Version (OBLIGATOIRE) :**
   ```
   Version 1.0 (Build X)
   
   ✨ Nouveautés :
   - Application RailSkills pour le suivi triennal réglementaire
   - Synchronisation SharePoint
   - Interface moderne iOS 18
   
   🐛 Corrections :
   - Améliorations de stabilité
   - Corrections diverses
   ```

   **b) Privacy Policy URL (OBLIGATOIRE pour TestFlight externe) :**
   - URL publique (ex: `https://votresite.com/privacy-policy`)
   - Doit être accessible sans authentification
   - En français
   - Décrit l'utilisation des données

   **c) Description (Optionnel mais recommandé) :**
   - Description de l'application
   - Instructions pour les testeurs

3. **Sauvegarder**

---

## 👥 ÉTAPE 8 : Ajouter des Testeurs Externes

### 8.1 Activer les Testeurs Externes

1. **TestFlight** → **External Testing** (à gauche)
2. **Cliquer sur "+"** pour créer un groupe
3. **Nom du groupe** : "Testeurs Externes" (ou autre)
4. **Ajouter le build** : Sélectionner le build uploadé
5. **Next**

### 8.2 Remplir les Informations de Test

1. **What to Test** (OBLIGATOIRE) :
   ```
   Cette version de RailSkills permet de :
   - Créer un compte et se connecter
   - Gérer le suivi triennal des conducteurs
   - Synchroniser avec SharePoint
   - Exporter les données
   
   Merci de tester toutes les fonctionnalités principales.
   ```

2. **Privacy Policy URL** : Même URL que dans l'étape 7.3

3. **Review Information** :
   - **First Name** : Votre prénom
   - **Last Name** : Votre nom
   - **Phone Number** : Votre numéro
   - **Email** : Votre email

4. **Submit for Review**

### 8.3 Inviter des Testeurs

1. **External Testing** → Votre groupe
2. **Onglet "Testers"**
3. **Cliquer sur "+"** pour ajouter des testeurs
4. **Entrer les emails** des testeurs (un par ligne)
5. **Add**

   ✅ Les testeurs recevront un email d'invitation

---

## ⏳ ÉTAPE 9 : Attendre la Révision Apple

1. **Statut** : "Waiting for Review" → "In Review" → "Ready to Test"

2. **Délai typique** :
   - **Première soumission** : 24-48 heures
   - **Mises à jour** : 12-24 heures

3. **Notifications** :
   - Email envoyé à chaque changement de statut
   - Vérifier régulièrement dans App Store Connect

4. **Si rejeté** :
   - Lire les raisons dans App Store Connect
   - Corriger les problèmes
   - Resoumettre (nouveau build requis)

---

## ✅ Checklist Finale

### Configuration Xcode
- [ ] Bundle identifier vérifié : `com.railskills.syl20.org.RailSkills`
- [ ] Team configuré : `UD44R8K7U8`
- [ ] Build number incrémenté
- [ ] Version définie : `1.0`
- [ ] Scheme configuré en Release
- [ ] Signing automatique activé

### Archive
- [ ] Build nettoyé (⇧⌘K)
- [ ] Destination : "Any iOS Device"
- [ ] Archive créée avec succès
- [ ] Archive validée sans erreur

### Upload
- [ ] Archive uploadée vers App Store Connect
- [ ] Upload réussi sans erreur

### App Store Connect
- [ ] App créée (si première fois)
- [ ] Build visible dans TestFlight
- [ ] Build "Ready to Submit"
- [ ] Notes de version remplies
- [ ] Privacy Policy URL fournie
- [ ] Groupe de testeurs externes créé
- [ ] Informations de test remplies
- [ ] Soumis pour révision

---

## 🆘 Résolution de Problèmes Courants

### Erreur : "No signing certificate found"

**Solution :**
1. Xcode → Preferences → Accounts
2. Sélectionner votre compte Apple
3. Cliquer sur "Download Manual Profiles"
4. Vérifier que le certificat est valide

### Erreur : "Bundle identifier already exists"

**Solution :**
- Utiliser un bundle ID différent
- Ou supprimer l'app existante dans App Store Connect

### Erreur : "Invalid binary"

**Solution :**
- Vérifier les logs dans App Store Connect
- Vérifier que toutes les permissions sont décrites dans Info.plist
- Vérifier que l'app compile sans erreur

### Build ne apparaît pas dans TestFlight

**Solution :**
- Attendre 30 minutes (traitement Apple)
- Vérifier que l'upload s'est bien terminé
- Vérifier les emails d'erreur d'Apple

### Erreur de provisioning profile

**Solution :**
1. Signing & Capabilities
2. Décocher puis recocher "Automatically manage signing"
3. Laisser Xcode régénérer les profils

---

## 📚 Ressources

- **Documentation Apple** : [App Store Connect Help](https://help.apple.com/app-store-connect/)
- **Guide TestFlight** : [TestFlight Documentation](https://developer.apple.com/testflight/)
- **Privacy Policy Template** : `Documentation/PRIVACY_POLICY_TEMPLATE.md`
- **Notes de Version Template** : `Documentation/NOTES_VERSION_TESTFLIGHT.md`

---

## 🎯 Résumé Rapide

1. ✅ **Vérifier** la configuration Xcode (Bundle ID, Team, Build)
2. ✅ **Incrémenter** le build number
3. ✅ **Créer** l'archive (Product → Archive)
4. ✅ **Valider** l'archive
5. ✅ **Uploader** vers App Store Connect
6. ✅ **Configurer** dans TestFlight (notes, privacy policy)
7. ✅ **Soumettre** pour révision externe
8. ✅ **Attendre** l'approbation Apple (24-48h)

---

**Votre app est maintenant prête pour TestFlight externe ! 🚀**

**Temps estimé total :** 1-2 heures (hors attente de révision Apple)






