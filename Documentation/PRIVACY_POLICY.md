# Politique de Confidentialité - RailSkills

**Dernière mise à jour :** 9 décembre 2025

---

## 1. Introduction

RailSkills est une application iOS/iPadOS développée pour la SNCF permettant aux Manager Traction et ARC (Adjoints Référents Conduite) de gérer le suivi réglementaire des conducteurs circulant au Luxembourg.

Cette politique de confidentialité explique comment RailSkills collecte, utilise et protège vos données personnelles.

---

## 2. Données Collectées

### 2.1 Données de l'Application

RailSkills collecte et stocke localement les données suivantes :

- **Informations sur les conducteurs :**
  - Nom (obligatoire)
  - Prénom (optionnel)
  - Numéro de CP - Certificat de Capacité Professionnelle (optionnel)
  - Date de début de période triennale
  - Date de dernière évaluation

- **Données d'évaluation par checklist :**
  - **Checklist Triennale** : États des questions (0=non validé, 1=partiel, 2=validé, 3=non traité), notes par question, dates de suivi
  - **Checklist VP (Visite Périodique)** : États, notes et dates de suivi
  - **Checklist TE (Test d'Évaluation)** : États, notes et dates de suivi

- **Métadonnées :**
  - Identifiant unique (UUID) pour chaque conducteur
  - Identifiant du CTT propriétaire (`ownerSNCFId`) - optionnel
  - Date d'export (pour les fichiers exportés)

### 2.2 Données de Synchronisation SharePoint (Optionnel)

Si la synchronisation SharePoint est activée et configurée :

- Les données sont synchronisées avec SharePoint (Microsoft 365 SNCF)
- L'authentification utilise Azure AD (Azure Active Directory)
- Les données restent dans l'environnement Microsoft 365 de la SNCF
- Structure de stockage isolée par CTT : `RailSkills/CTT_{cttId}/Data/` et `RailSkills/Checklists/`
- Chaque CTT ne peut accéder qu'à ses propres données

### 2.3 Données Techniques

L'application peut collecter les informations suivantes pour le fonctionnement technique :

- **Version de l'application** : Pour le support technique et la compatibilité
- **Logs d'erreurs** : Uniquement pour le débogage (pas de données personnelles)
- **Identifiant de session** : Pour la synchronisation SharePoint (si activée)

**Note :** Aucun identifiant publicitaire (IDFA) n'est collecté. Aucun tracking n'est effectué.

---

## 3. Utilisation des Données

### 3.1 Utilisation Principale

Les données collectées sont utilisées uniquement pour :

- Permettre le suivi des évaluations réglementaires des conducteurs
  - Suivi triennal (checklist triennale)
  - Visites périodiques (checklist VP)
  - Tests d'évaluation (checklist TE)
- Synchroniser les données entre différents appareils (si SharePoint activé)
- Générer des rapports PDF avec en-têtes personnalisés
- Exporter/importer des données au format JSON (avec compression et chiffrement optionnels)
- Recherche dans les notes et données des conducteurs

### 3.2 Partage des Données

- **Aucune donnée n'est partagée avec des tiers externes**
- Les données restent dans l'environnement SNCF (si SharePoint utilisé)
- Les données peuvent être exportées localement par l'utilisateur (format JSON)
- Les exports peuvent être chiffrés avec AES-GCM et compressés avec LZFSE
- Les données peuvent être partagées via QR code (format JSON chiffré)

---

## 4. Stockage et Sécurité

### 4.1 Stockage Local

- Les données sont stockées localement sur votre appareil iOS/iPadOS
- Utilisation de `UserDefaults` pour la persistance des données
- Format de stockage : JSON encodé
- Les données sont isolées par application (sandbox iOS)

**Données stockées localement :**
- Liste des conducteurs (`drivers`)
- Checklist triennale (`lastChecklist`)
- Checklist VP (`lastChecklistVP`)
- Checklist TE (`lastChecklistTE`)
- Préférences de synchronisation SharePoint

### 4.2 Stockage SharePoint (Optionnel)

Si la synchronisation SharePoint est activée :

- Les données sont stockées dans SharePoint (Microsoft 365 SNCF)
- Site SharePoint : `sncf.sharepoint.com:/sites/railskillsgrpo365`
- Structure de dossiers :
  ```
  RailSkills/
  ├── CTT_{cttId}/          # Dossier isolé par CTT
  │   └── Data/
  │       └── {nom-conducteur}/
  │           ├── {nom-conducteur}.json
  │           └── {nom-conducteur}_backup.json
  └── Checklists/
      ├── questions_CFL.json      # Checklist triennale
      ├── questions_VP.json       # Checklist VP
      └── questions_TE.json       # Checklist TE
  ```
- Accès limité au CTT propriétaire des données (validation via `ownerSNCFId`)
- Conformité avec les règles de sécurité SNCF
- Synchronisation bidirectionnelle avec gestion des conflits

### 4.3 Chiffrement et Compression

**Exports de données :**
- **Chiffrement** : AES-GCM (Advanced Encryption Standard - Galois/Counter Mode)
- **Compression** : LZFSE (Apple Lossless Compression)
- **Secret organisationnel** : Requis pour le déchiffrement (partagé via QR code ou saisie manuelle)
- **Format export** : JSON avec métadonnées (date d'export, version, informations exportateur)

**Par défaut :**
- Les exports de conducteurs sont chiffrés et compressés
- Les exports de checklists peuvent être non chiffrés (selon le contexte)

---

## 5. Permissions de l'Application

RailSkills peut demander les permissions suivantes (toutes optionnelles) :

### 5.1 Reconnaissance Vocale (Optionnelle)

- **Usage :** Pour la dictée de notes dans les évaluations
- **Description système :** "La reconnaissance vocale peut être utilisée pour la dictée de notes dans les évaluations."
- **Stockage :** Les données vocales ne sont pas stockées, seule la transcription textuelle est enregistrée dans les notes
- **Traitement :** Effectué localement sur l'appareil (pas d'envoi vers des serveurs externes)

### 5.2 Microphone (Optionnelle)

- **Usage :** Pour la dictée vocale des notes d'évaluation
- **Description système :** "Le microphone peut être utilisé pour la dictée vocale des notes d'évaluation."
- **Stockage :** Aucun enregistrement audio n'est stocké, seule la transcription est sauvegardée
- **Accès :** Uniquement pendant la saisie de notes (pas d'accès en arrière-plan)

### 5.3 Caméra (Non utilisée actuellement)

- **Usage prévu :** Pour scanner des QR codes afin d'importer le secret de chiffrement
- **Statut :** Permission non implémentée dans la version actuelle (1.2)
- **Note :** Si cette fonctionnalité est ajoutée, une description d'usage sera ajoutée dans cette politique

---

## 6. Vos Droits (RGPD)

Conformément au Règlement Général sur la Protection des Données (RGPD), vous disposez des droits suivants :

- **Droit d'accès** : Vous pouvez exporter toutes vos données depuis l'application (format JSON)
- **Droit de rectification** : Vous pouvez modifier vos données directement dans l'application
- **Droit à l'effacement** : Vous pouvez supprimer les conducteurs et leurs données via l'application
- **Droit à la portabilité** : Export des données en format JSON disponible (avec ou sans chiffrement)
- **Droit d'opposition** : Vous pouvez désactiver la synchronisation SharePoint à tout moment
- **Droit à la limitation** : Vous pouvez utiliser l'application en mode local uniquement (sans SharePoint)

**Pour exercer vos droits :**
- Export des données : Réglages → Export/Import → Exporter les données
- Suppression : Supprimer un conducteur depuis la liste des conducteurs
- Désactivation SharePoint : Réglages → Synchronisation SharePoint → Désactiver

---

## 7. Conservation des Données

### 7.1 Données Locales

- Les données sont conservées tant que l'application est installée sur l'appareil
- En cas de désinstallation de l'application, les données locales sont automatiquement supprimées par iOS
- Les données peuvent être exportées avant désinstallation pour sauvegarde

### 7.2 Données SharePoint

- Les données SharePoint sont conservées selon la politique de rétention SNCF
- En cas de désactivation de la synchronisation, les données restent sur SharePoint
- La suppression des données SharePoint doit être effectuée manuellement depuis SharePoint

### 7.3 Exports

- Les fichiers exportés sont stockés où vous les avez sauvegardés (Fichiers iOS, AirDrop, etc.)
- La suppression des exports est de votre responsabilité

---

## 8. Confidentialité des Données

### 8.1 Isolation des Données

- Chaque CTT ne peut accéder qu'à ses propres données
- Validation de l'identité via `ownerSNCFId` ou `cttId` lors de la synchronisation SharePoint
- Pas d'accès croisé entre différents CTT
- Filtrage automatique des données par propriétaire lors de la synchronisation

### 8.2 Logs et Audit

- Les actions importantes sont enregistrées dans les logs d'application
- Les logs incluent : ajout, modification, suppression, import, export, synchronisation
- **Aucune donnée personnelle n'est enregistrée dans les logs** (pas de noms, emails, etc.)
- Les logs sont stockés localement uniquement (pas d'envoi vers des serveurs externes)

### 8.3 Mode Démonstration

- L'application dispose d'un mode démonstration pour les tests
- Les données de démonstration sont isolées et ne se synchronisent pas avec les vraies données
- Le mode démo utilise un identifiant distinct (`demo.reviewer@sncf.fr`)

---

## 9. Cookies et Traçage

RailSkills n'utilise **aucune** technologie de traçage :

- ❌ Pas de cookies
- ❌ Pas d'identifiant publicitaire (IDFA)
- ❌ Pas d'analytics tiers
- ❌ Pas de tracking cross-app
- ❌ Pas de partage de données avec des réseaux publicitaires

**Conformité App Store :**
- Data Collection: None
- Data Used to Track You: None
- Data Linked to You: None (sauf données synchronisées avec SharePoint si activé)

---

## 10. Synchronisation SharePoint

### 10.1 Configuration

La synchronisation SharePoint est **optionnelle** et nécessite :

- Une configuration manuelle dans l'application (Réglages → Synchronisation SharePoint)
- Les identifiants Azure AD (Client ID, Tenant ID, Client Secret)
- Une authentification Azure AD valide
- Un accès au site SharePoint SNCF

### 10.2 Fonctionnement

- **Synchronisation automatique** : Activée par défaut (peut être désactivée)
- **Synchronisation bidirectionnelle** : Les modifications locales et SharePoint sont synchronisées
- **Gestion des conflits** : En cas de modification simultanée, la version la plus récente est prioritaire
- **Débouncing** : Les sauvegardes sont regroupées pour éviter les synchronisations excessives

### 10.3 Sécurité

- Authentification via OAuth 2.0 (Azure AD)
- Tokens d'accès stockés de manière sécurisée
- Connexions HTTPS uniquement
- Pas de secrets hardcodés dans l'application

---

## 11. Modifications de la Politique

Cette politique de confidentialité peut être modifiée pour refléter les évolutions de l'application.

- La date de dernière mise à jour est indiquée en haut du document
- Les modifications importantes seront communiquées via les notes de version de l'application
- La version actuelle de cette politique s'applique à RailSkills version 1.2+

---

## 12. Contact

Pour toute question concernant cette politique de confidentialité ou la protection de vos données :

**Développeur :** Sylvain GALLON  
**Email :RailSkills@syl20.org  
**Application :** RailSkills  
**Version actuelle :** 1.2  
**Plateforme :** iOS 18+ / iPadOS 18+

---

## 13. Conformité

RailSkills est conforme aux exigences suivantes :

- ✅ **RGPD** (Règlement Général sur la Protection des Données - UE)
- ✅ **Loi Informatique et Libertés** (France)
- ✅ **Guidelines Apple App Store** (Privacy, Data Collection, Permissions)
- ✅ **Politique de sécurité SNCF** (si applicable pour SharePoint)
- ✅ **Standards de chiffrement** (AES-GCM)

---

## 14. Informations Techniques

### 14.1 Formats de Données

- **Stockage local** : JSON encodé dans UserDefaults
- **Export** : JSON avec compression LZFSE et chiffrement AES-GCM optionnel
- **Dates** : Format ISO 8601
- **Identifiants** : UUID standard

### 14.2 Compatibilité

- **iOS minimum** : iOS 16.0
- **iPadOS minimum** : iPadOS 16.0
- **Appareils supportés** : iPad et iPhone
- **Orientations** : Portrait et Paysage (toutes orientations sur iPad)

---

**Cette politique de confidentialité s'applique à la version 1.2+ de RailSkills pour iOS 16+ / iPadOS 16+**

**Date de création :** 3 décembre 2025  
**Dernière mise à jour :** 9 décembre 2025
