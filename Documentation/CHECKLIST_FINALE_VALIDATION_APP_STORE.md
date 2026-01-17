# ✅ Checklist Finale - Validation App Store RailSkills

**Date :** 11 décembre 2025  
**Version :** 1.2  
**Statut :** En cours de préparation

---

## ✅ CE QUI EST DÉJÀ FAIT

### Documents et URLs
- [x] Privacy Policy créée et mise à jour (version 1.2)
- [x] Support page créée (SUPPORT.md)
- [x] URLs GitHub Pages fonctionnelles
- [x] Dépôt public créé et déployé
- [x] Mode démo implémenté pour reviewers Apple

### Code et Configuration
- [x] Secrets supprimés du code
- [x] Entitlements inutilisés retirés
- [x] Background modes inutilisés retirés
- [x] Conformité Apple vérifiée
- [x] 3 checklists implémentées (Triennale, VP, TE)
- [x] Checklists VP et TE uploadées sur SharePoint

### GitHub
- [x] Dépôt privé créé (code source)
- [x] Dépôt public créé (fichiers pour Apple)
- [x] GitHub Pages activé

---

## 🔴 CRITIQUES (À Faire Avant Soumission)

### 1. Tests sur Appareil Réel
- [ ] **Tester sur iPad réel** (pas seulement simulateur)
  - [ ] Vérifier toutes les fonctionnalités
  - [ ] Tester les 3 onglets (Suivi, VP, TE)
  - [ ] Vérifier qu'il n'y a pas de crash
  - [ ] Tester le mode démo
  - [ ] Vérifier la synchronisation SharePoint (si configurée)

- [ ] **Tester sur iPhone réel** (si supporté)
  - [ ] Vérifier l'interface compacte
  - [ ] Tester la navigation
  - [ ] Vérifier qu'il n'y a pas de crash

### 2. Mettre à Jour le Mode Démo
- [ ] **Vérifier que le mode démo inclut les 3 checklists**
  - [ ] Checklist Triennale chargée en mode démo
  - [ ] Checklist VP chargée en mode démo
  - [ ] Checklist TE chargée en mode démo
  - [ ] Tester que les 3 onglets fonctionnent en mode démo

### 3. Créer l'App dans App Store Connect
- [ ] Aller sur https://appstoreconnect.apple.com
- [ ] My Apps → "+" → New App
- [ ] Remplir :
  - Platform : **iOS**
  - Name : **RailSkills**
  - Primary Language : **French**
  - Bundle ID : **com.railskills.syl20.org.RailSkills** (ou votre ID)
  - SKU : **RailSkills-iOS-001**

### 4. Remplir les Métadonnées App Store
- [ ] **Description de l'app** (français, 4000 caractères max)
  ```
  RailSkills est une application professionnelle développée pour la SNCF 
  permettant aux Manager Traction et ARC (Adjoints Référents Conduite) 
  de gérer le suivi réglementaire des conducteurs circulant au Luxembourg.

  Fonctionnalités :
  • Suivi triennal réglementaire (checklist triennale)
  • Validations périodiques (checklist VP)
  • Trains d'essai (checklist TE)
  • Gestion des conducteurs avec progression détaillée
  • Dashboard avec graphiques triennaux
  • Export/Import de données (JSON, PDF)
  • Synchronisation SharePoint optionnelle
  • Interface adaptée iPad et iPhone

  Cette application est destinée à un usage professionnel interne SNCF.
  ```

- [ ] **Mots-clés** (100 caractères max)
  ```
  conducteurs, sncf, évaluation, traction, cfl, compétences, vp, te, 
  visite périodique, test évaluation, réglementaire
  ```

- [ ] **Catégorie**
  - Principale : **Business** (Entreprise)
  - Secondaire : **Productivity** (Productivité)

- [ ] **Screenshots** (OBLIGATOIRE)
  - [ ] Screenshots iPad (minimum 1, recommandé 3-5)
    - Format : 2048x2732 (iPad Pro 12.9")
    - Formats acceptés : 2048x2732, 1668x2388, 1536x2048
  - [ ] Screenshots iPhone (si supporté)
    - Format : 1242x2688 (iPhone XS Max)
  - [ ] Capturer les écrans principaux :
    - Écran de connexion avec mode démo
    - Dashboard avec graphiques
    - Liste des conducteurs
    - Checklist (onglet Suivi)
    - Checklist VP
    - Checklist TE

- [ ] **Icône de l'app** (1024x1024 pixels)
  - [ ] Format PNG
  - [ ] Pas de transparence
  - [ ] Pas de coins arrondis (Apple les ajoute)

### 5. App Review Information
- [ ] **Contact Information**
  - [ ] Contact email : RailSkills@syl20.org
  - [ ] Téléphone de contact
  - [ ] Notes pour reviewers :
    ```
    Mode démonstration disponible : 
    Sur l'écran de connexion, cliquer sur le bouton "Mode démonstration" 
    pour accéder à toutes les fonctionnalités avec des données de démonstration.
    
    L'application dispose de 3 onglets de suivi :
    - Suivi (checklist triennale)
    - VP (Visite Périodique)
    - TE (Test d'Évaluation)
    
    Toutes les fonctionnalités sont accessibles en mode démo.
    ```

- [ ] **Privacy Policy URL**
  ```
  https://syl20mac.github.io/RailSkills-Public/PRIVACY_POLICY.html
  ```

- [ ] **Support URL** (optionnel mais recommandé)
  ```
  https://syl20mac.github.io/RailSkills-Public/SUPPORT.html
  ```

### 6. Export Compliance
- [ ] **Uses Encryption** : YES
- [ ] **Exempt from export compliance** : YES (standard encryption only)
  - Justification : L'app utilise uniquement le chiffrement standard iOS (AES-GCM pour les exports)

---

## 🟡 IMPORTANTS (Fortement Recommandés)

### 7. Tests TestFlight
- [ ] **Incrémenter le Build Number**
  - [ ] Vérifier le build number actuel dans `Configs/Info.plist`
  - [ ] Incrémenter si nécessaire (chaque upload doit avoir un build unique)

- [ ] **Créer l'Archive Release**
  - [ ] Xcode → Product → Clean Build Folder (⇧⌘K)
  - [ ] Sélectionner "Any iOS Device"
  - [ ] Product → Archive
  - [ ] Attendre la fin de l'archive

- [ ] **Valider l'Archive**
  - [ ] Window → Organizer
  - [ ] Sélectionner l'archive
  - [ ] Validate App
  - [ ] Corriger les erreurs si nécessaire

- [ ] **Uploader vers App Store Connect**
  - [ ] Distribute App → App Store Connect
  - [ ] Suivre l'assistant
  - [ ] Upload
  - [ ] Attendre le processing (15-30 minutes)

- [ ] **Tests Internes TestFlight**
  - [ ] Tester sur votre propre appareil
  - [ ] Vérifier toutes les fonctionnalités
  - [ ] Tester le mode démo
  - [ ] Tester les 3 onglets (Suivi, VP, TE)

- [ ] **Tests Externes TestFlight** (optionnel mais recommandé)
  - [ ] Inviter 2-3 utilisateurs CTT
  - [ ] Collecter les retours
  - [ ] Corriger les bugs identifiés

### 8. Notes de Version
- [ ] **Rédiger les notes de version** pour TestFlight et App Store
  ```
  Version 1.2 (Build X)
  
  ✨ Nouveautés :
  - Ajout des onglets VP (Visite Périodique) et TE (Test d'Évaluation)
  - Support de 3 checklists indépendantes
  - Synchronisation SharePoint pour les checklists VP et TE
  - Améliorations de l'interface utilisateur
  
  🐛 Corrections :
  - Améliorations diverses
  - Corrections de bugs
  ```

---

## 🟢 OPTIONNELS (Améliorations)

### 9. Accessibilité
- [ ] Tester avec VoiceOver
- [ ] Vérifier les labels d'accessibilité
- [ ] Tester Dynamic Type (tailles extrêmes)

### 10. Mode Sombre
- [ ] Vérifier que l'interface fonctionne en mode sombre
- [ ] Corriger les contrastes si nécessaire

### 11. Localisation
- [ ] Vérifier que tous les textes sont en français
- [ ] Optionnel : préparer la traduction anglaise

### 12. Video Preview
- [ ] Créer une vidéo de démonstration (optionnel)
- [ ] Montrer les fonctionnalités principales

---

## 📋 Checklist Avant Submit for Review

### Documents et URLs ✅
- [x] Privacy Policy URL configurée
- [x] Support URL configurée (optionnel)
- [x] URLs accessibles et testées

### Métadonnées
- [ ] Description de l'app rédigée
- [ ] Mots-clés remplis
- [ ] Catégorie sélectionnée
- [ ] Screenshots ajoutés (iPad minimum)
- [ ] Icône de l'app (1024x1024)

### App Review Information
- [ ] Contact email et téléphone
- [ ] Notes pour reviewers (mode démo)
- [ ] Privacy Policy URL
- [ ] Support URL (optionnel)

### Build
- [ ] Archive créée et validée
- [ ] Build uploadé sur App Store Connect
- [ ] Build en statut "Ready to Submit"
- [ ] Build number incrémenté

### Tests
- [ ] Testé sur iPad réel
- [ ] Mode démo testé
- [ ] Aucun crash détecté
- [ ] Toutes les fonctionnalités testées

---

## 🚀 Ordre Recommandé des Actions

### Semaine 1 : Préparation
1. **Tester sur iPad réel** (1-2 heures)
2. **Vérifier le mode démo** avec les 3 checklists (30 min)
3. **Créer l'app dans App Store Connect** (15 min)
4. **Remplir les métadonnées de base** (30 min)
5. **Prendre les screenshots** (1-2 heures)

### Semaine 2 : Upload et Tests
6. **Créer l'archive et uploader** (1 heure)
7. **Tester sur TestFlight** (1-2 heures)
8. **Corriger les bugs éventuels** (selon les retours)
9. **Re-uploader si nécessaire**

### Semaine 3 : Soumission
10. **Finaliser les métadonnées** (30 min)
11. **Remplir App Review Information** (15 min)
12. **Submit for Review** (5 min)
13. **Attendre la validation** (24-48h)

---

## 📊 Estimation Temps Total

- **Actions critiques** : ~6-8 heures
- **Tests** : ~2-4 heures
- **Upload et configuration** : ~2-3 heures
- **Total** : ~10-15 heures de travail réparties sur 2-3 semaines

---

## 🎯 URLs à Utiliser

### Privacy Policy URL
```
https://syl20mac.github.io/RailSkills-Public/PRIVACY_POLICY.html
```

### Support URL
```
https://syl20mac.github.io/RailSkills-Public/SUPPORT.html
```

---

## ✅ Résumé

**Déjà fait :**
- ✅ Privacy Policy et Support créés
- ✅ URLs GitHub Pages fonctionnelles
- ✅ Mode démo implémenté
- ✅ Code conforme Apple
- ✅ Secrets supprimés

**À faire maintenant :**
1. Tester sur iPad réel
2. Vérifier le mode démo avec les 3 checklists
3. Créer l'app dans App Store Connect
4. Prendre les screenshots
5. Remplir les métadonnées
6. Uploader le build
7. Soumettre pour review

---

**Votre app est presque prête ! Il reste principalement des actions de configuration et de test. 🚀**








