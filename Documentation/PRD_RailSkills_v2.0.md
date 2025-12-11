# **PRD – RailSkills v2.1**

**Auteur :** Sylvain Gallon  
**Version logiciel visée :** 2.1 (novembre 2025)  
**Plateformes :** iPhone (iOS 16+), iPad (iPadOS 16+)  
**Technologies :** SwiftUI • Combine • AVFoundation • CoreImage • NSUbiquitousKeyValueStore

---

## 0. Résumé exécutif

RailSkills fournit aux **Manager Traction** et **Adjoints Référents Conduite (ARC)** un outil mobile pour piloter les suivis réglementaires des conducteurs SNCF circulant au Luxembourg. L'application, entièrement locale et synchronisable via iCloud, offre :

- Gestion complète des conducteurs et des échéances triennales.
- Suivi détaillé des checklists dynamiques (importées via JSON/texte).
- Notes, dates de suivi et progression temps réel par question et catégorie.
- Export/import sécurisé (JSON, QR, PDF, CSV) avec stratégie de fusion.
- Dashboard avec statistiques globales et vue d'ensemble.
- Interface adaptative iPhone/iPad, modes d'interaction configurables.
- Notifications toast pour le feedback utilisateur.

---

## 1. Objectifs produit

1. Garantir la traçabilité réglementaire (suivis triennaux, signatures numériques futures).
2. Centraliser les dossiers conducteurs sans dépendre d'un réseau externe.
3. Simplifier la collaboration entre Manager Traction/ARC (imports/exports, QR codes, fusion intelligente).
4. Offrir une UX adaptée terrain : gestes rapides, filtres, mode sombre, accessibilité.
5. Faciliter l'export de données pour traitement externe (Excel via CSV).

---

## 2. Parties prenantes

| Rôle | Besoin | Valeur apportée |
|------|--------|-----------------|
| **Manager Traction** | suivre certifications, préparer contrôles | vue synthèse, export PDF/JSON/CSV, dashboard |
| **ARC** | réaliser suivis partagés, préparer supports | import QR, édition mobile, partage QR |
| **Conducteurs** | accéder à leur progression via PDF | transparence, traçabilité |
| **DSIT / Sécurité** | fiabilité, conformité, résilience | données locales, iCloud optionnel, chiffrement |

---

## 3. Expérience utilisateur

### 3.1 Navigation générale
- **TabView** (6 onglets) : `Suivi`, `Éditeur`, `Partage`, `Dashboard`, `Rapports`, `Réglages`.
- State global `AppViewModel` (ObservableObject) partagé dans toutes les vues.
- Système de notifications toast pour feedback utilisateur (`ToastNotificationManager`).

### 3.2 Suivi (Onglet 0)
- **iPhone (compact)** :
  - Panneau conducteur (sélecteur/menu + bouton d'ajout, stats échéance).
  - Carte progression globale : `CircularProgressView` + barre horizontale.
  - Avertissement si aucun conducteur actif (actions `Créer` / `Importer`).
  - **Menu de filtre** (Menu SwiftUI) : `Tout`, `Validé`, `Partiel`, `Non validé`, `Non traité`.
  - Catégories repliées par défaut, ouverture individuelle animée. Plusieurs catégories peuvent rester ouvertes tant que l'utilisateur ne referme pas tout.
  - Chaque carte affiche progression (0/7, 45 %), `ProgressView`, bouton pour exporter/notes.
  - Questions rendues via `ChecklistRow` : toggle 4 états optimisé iPhone (gestes horizontaux uniquement), note rapide, date de suivi.
  - Recherche dans les titres et notes.

- **iPad (regular)** :
  - `NavigationSplitView` : sidebar catégories + panneau détail questions.
  - Barre de recherche locale dans le panneau droit + filtre menu identique.
  - `CircularProgressView` dans l'entête de catégorie.

### 3.3 Éditeur (Onglet 1)
- List SwiftUI modulaire : catégories, questions triées chronologiquement.
- Actions :
  - Ajouter catégorie/question (toolbar menu).
  - Conversion catégorie ↔ question, insertion après index, édition inline.
  - **Suppression** : swipe trailing + confirmation, ou via bouton dans `ChecklistEditorRow`.
  - Import de checklist (fichier JSON/texte) + import conducteurs (JSON) avec dialogue de fusion (`MergeStrategy`).
  - Section synthèse conducteurs : carte récap + boutons `Ajouter un conducteur` / `Importer depuis un fichier` → `DriversManagerView`.

### 3.4 Partage (Onglet 2)
- **Export d'un conducteur** :
  - Exporter en JSON (fichier avec compression et chiffrement optionnel).
  - Exporter en CSV (compatible Excel, UTF-8 avec BOM).
  - Générer QR code (partage sans réseau, avec compression automatique si nécessaire).

- **Export de plusieurs conducteurs** :
  - Sélection multiple (mode édition).
  - Export en JSON compressé.
  - Export en CSV pour traitement Excel.

- **Export de la checklist** :
  - Exporter en JSON.
  - Générer QR code.

- **Import** :
  - Import conducteurs depuis fichier JSON (multi ou single record).
  - Scanner QR code (conducteur ou checklist).
  - Fusion intelligente avec stratégies multiples (remplacer, conserver plus récent, fusionner états).

### 3.5 Dashboard (Onglet 3) - NOUVEAU
- **Vue d'ensemble** :
  - Cartes statistiques : nombre total de conducteurs, questions totales, progression moyenne.
  - Triennale : liste des échéances prochaines avec codes couleur (vert/orange/rouge).
  - Répartition de progression du conducteur sélectionné (graphique en barres).

### 3.6 Rapports (Onglet 4)
- Génération PDF via `UIGraphicsPDFRenderer` :
  - Page de couverture avec informations conducteur et progression globale.
  - Table des matières (si plusieurs catégories).
  - Détail complet par catégorie avec états, dates de suivi, notes.
  - Page de synthèse statistique (répartition par état, progression par catégorie).
  - En-têtes et numéros de page.
- Export multiplateforme (AirDrop, Files, etc.).
- Sélection de conducteurs multiples pour rapport groupé.

### 3.7 Réglages (Onglet 5)
- **Mode d'interaction** :
  - Prévisualisation instantanée (Toggle / Segment / Boutons / Menu).
  - Choix du mode stocké via `@AppStorage`.
  
- **Synchronisation iCloud** :
  - Activation/désactivation (`Store.setiCloudSyncEnabled`).
  - Indicateur de statut de synchronisation (`iCloudSyncIndicatorView`).
  - Dernière date de synchronisation affichée.

- **Gestion des clés de chiffrement** (NOUVEAU) :
  - Configuration du secret organisationnel pour le chiffrement des exports.
  - Partage du secret via QR code pour synchronisation entre appareils.
  - Scanner QR code pour importer le secret.
  - Réinitialisation du secret (avec alerte de confirmation).

- **Statistiques globales** :
  - Nombre total de conducteurs.
  - Nombre total de questions.
  - Progression moyenne globale.
  - Dernière mise à jour.

- **Réinitialisation** :
  - Alerte de confirmation sur bouton `Terminé`.
  - Suppression complète de toutes les données.

---

## 4. Fonctionnalités principales et règles métier

### 4.1 Suivi & évaluation
- Toggle 4 états : `QuadStateToggle`, `Segmented`, `Buttons`, `Menu`. Transition animée, accessible (VoiceOver, adjustableAction).
- Sauvegarde :
  - `AppViewModel.setState()` → update `store.drivers[selected].checklistStates` + refresh caches (progress, notes, sections).
  - Date de suivi stockée (`checklistDates`) + mise à jour `selectedDriver.lastEvaluation`.
- Notes : `NoteEditorSheet` (TextEditor) + preview sur carte (tap pour agrandir).
- Recherche : appliquée aux titres des questions et aux notes de tous les conducteurs.

### 4.2 Gestion conducteurs
- `DriversManagerView` intégré à l'onglet `Éditeur` (NavigationLink). Ajout, édition (Form), suppression (alerte).
- Tri automatique par urgence (`daysRemaining`).
- Import depuis JSON (multi ou single record) + fusion intelligente (`MergeStrategy`).
- Export (mono/multi) compressé en JSON avec chiffrement optionnel, métadonnées version/date.

### 4.3 Checklist dynamique
- Checklist vide au lancement (pas de données embarquées).
- Import depuis JSON/Markdown (via `ChecklistParser`).
- Édition :
  - Ajout question/catégorie (id UUID, titre par défaut).
  - Conversion type (conserve id, notes, état).
  - Suppression cascade (catégorie supprime ses questions) avec confirmation.
- Cache sections : `ContentView.updateSectionsCache()` (filtrage, progress category).

### 4.4 Recherche & filtrage
- Recherche `searchText` appliquée à toutes les questions et notes.
- Filtre `ChecklistFilter` : adapte sections (catégories conservées même si vides, message "aucune question").
- iPhone : catégories repliées si `collapsedAllCompact == true`; expansion multiple autorisée.

### 4.5 Export / Import & iCloud
- `Store` (annoté `@MainActor`) :
  - `@AppStorage` (UserDefaults) pour drivers/checklist.
  - `NSUbiquitousKeyValueStore` pour iCloud (drivers + checklist).
  - Debounce (300 ms local, 500 ms iCloud) via Combine.
  - Notification iCloud traitée via `Task { @MainActor ... }` pour éviter assertions.

- **Export JSON** :
  - Compression LZFSE optionnelle.
  - Chiffrement AES-GCM optionnel (par défaut activé pour les conducteurs, désactivé pour QR codes).
  - Métadonnées (date export, version format, exporter info).

- **Export CSV** (NOUVEAU) :
  - Format compatible Excel (séparateur point-virgule, UTF-8 avec BOM).
  - Colonnes : Nom conducteur, Date début triennale, Échéance, Jours restants, Catégorie, Question, État, État (texte), Date de suivi, Note.
  - Échappement automatique des caractères spéciaux.
  - Export pour un ou plusieurs conducteurs.

- **Export QR Code** (AMÉLIORÉ) :
  - Génération via `QRCodeService` (CoreImage).
  - Encodage base64 des données JSON.
  - Compression automatique si données > 2900 caractères (limite QR code correction H).
  - Partage d'image QR code via sélecteur système.
  - Support conducteur et checklist.

- **Import QR Code** (NOUVEAU) :
  - Scanner via `QRScannerView` (AVFoundation).
  - Détection automatique du type (conducteur ou checklist).
  - Décompression automatique si nécessaire.
  - Fusion intelligente pour conducteurs existants.

- **PDF** : `PDFReportGenerator` avec page de couverture, table des matières, synthèse statistique, en-têtes paginés.

- Merge import : `AppViewModel.mergeDriver(_:at:strategy:)` (replace, keepNewer, mergeStates).

### 4.6 Accessibilité & expérience
- `QuadStateToggle` : drag horizontal uniquement (minimumDistance 0, filtrage vertical, tap incrémental).
- iPhone : catégories repliées par défaut pour limiter le scroll, expansion animée.
- Couleurs catégorie : bleu (progression en cours), vert (complète). Affichage iPhone sans barre latérale pour limiter la surcharge.
- Avertissements : absence conducteur, import échoué, fusion en attente.
- **Notifications toast** (NOUVEAU) : feedback visuel temporaire pour actions utilisateur (succès, erreur, info).
- **VoiceOver** : labels et hints sur tous les éléments interactifs.

### 4.7 Validation des données (NOUVEAU)
- `ValidationService` pour validation des noms de conducteurs, checklists, et fichiers partagés.
- Sanitisation des noms de fichiers pour export.
- Vérification de l'intégrité des données importées.

---

## 5. Architecture technique

### 5.1 MVVM
- `AppViewModel` (ObservableObject) centralise store, caches, sélection.
- Extensions spécialisées : StateManagement, Notes, Progress, ChecklistManagement, DriverManagement, Sharing.
- Vues purement déclaratives, injection `@ObservedObject` ou `@StateObject`.

### 5.2 Persistance & synchronisation
- `Store` structure données :
  - `drivers` `[DriverRecord]` (id, name, triennialStart, states, notes, dates).
  - `checklist` `Checklist?` (title, items).
- Sauvegarde automatique sur modification (Combine `sink`).
- iCloud (Key-Value Store) pour drivers/checklist ; fallback UserDefaults si non activé.
- `Logger` pour traces (info, warning, success, error).

### 5.3 Modules & composants

**Vues principales :**
- `ContentView`, `ChecklistEditorView`, `DriversManagerView`, `SharingView`, `DashboardView`, `ReportsView`, `SettingsView`.

**Composants réutilisables :**
- `ChecklistRow`, `ChecklistEditorRow`, `ChecklistSection`, `CategorySectionView`.
- `StateInteractionView`, `QuadStateToggle`, `SegmentedStateControl`, `ButtonsStateControl`, `MenuStateControl`.
- `CircularProgressView`, `ProgressHeaderView`, `DriversPanelView`, `FilterMenuView`.
- `QRScannerView`, `QRCodeDisplayView`, `QRCodeScannerSheet`.
- `AddDriverSheet`, `NoteEditorSheet`, `ShareSheet`.
- `EncryptionKeyManagementView`, `iCloudSyncIndicatorView`.

**Services :**
- `Store` : Persistance UserDefaults/iCloud.
- `ChecklistParser` : Parsing Markdown/JSON.
- `PDFReportGenerator` : Génération rapports PDF avancés.
- `QRCodeService` : Génération QR codes.
- `ExportService` : Export/Import JSON, CSV avec compression et chiffrement.
- `EncryptionService` : Chiffrement AES-GCM avec secret organisationnel.
- `ValidationService` : Validation et sanitisation des données.
- `ToastNotificationManager` : Gestion des notifications toast.

**Utilities :**
- `ImportResult`, `MergeStrategy`, `InteractionMode`, `ChecklistFilter`.
- `Constants` (UI, Date, Debounce), `DateFormatHelper`, `Logger`.
- `Extensions` (Data compression, Color states, View helpers).

---

## 6. Données & modèles

```swift
struct ChecklistItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isCategory: Bool
}

struct Checklist: Codable {
    var title: String
    var items: [ChecklistItem]
    var questions: [ChecklistItem] { items.filter { !$0.isCategory } }
}

struct DriverRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var lastEvaluation: Date?
    var triennialStart: Date?
    var checklistStates: [String: [UUID: Int]]
    var checklistNotes: [String: [UUID: String]]
    var checklistDates: [String: [UUID: Date]]
}
```

`ShareableDriverRecord`, `ShareableDriversRecord` : encapsulation pour export/import (métadonnées `exportDate`, `exporterInfo`, `version`).

---

## 7. Sécurité & conformité

- Données toujours locales (UserDefaults) + option iCloud KVS.
- Pas de backend externe.
- Export sur action explicite (JSON / PDF / CSV / QR).
- **Chiffrement optionnel** (AES-GCM) pour exports JSON via secret organisationnel.
- Gestion des clés de chiffrement dans les réglages (partage QR).
- Effacement possible checklist/conducteurs (reset complet).
- Conformité RGPD : pseudonymisation, suppression, pas de collecte tiers.

---

## 8. Performances & résilience

- Caches : sections checklist, progression catégories, notes, états (invalidation sur modification).
- Debounce persistance pour limiter I/O.
- Gestion erreurs : alertes utilisateur (import, fusion, suppression) + notifications toast.
- MainActor pour `Store` + Task sur notifications iCloud (évite SIGTRAP `_dispatch_assert_queue_fail`).
- Compression LZFSE pour réductions de taille (exports, QR codes).

---

## 9. Roadmap & évolutions

| Version | Jalons | Détails |
|---------|--------|---------|
| **2.1** | Fonctionnalités avancées | Dashboard, CSV, QR codes complets, chiffrement, toast |
| **2.2** | PDF avancé | Signatures numériques, custom corporate, cache multi-pages |
| **2.3** | Collaboratif | Partage multi-appareils, validation croisée, audit log |
| **3.0** | Multi-checklists | Plusieurs contextes de suivi, assignation par conducteur |
| **3.x** | Notifications | Alertes échéance, rappel import, email synthèse |

---

## 10. Cas d'usage clés

1. **Premier lancement** : import checklist → ajout conducteur → suivi catégorie → export PDF.
2. **Contrôle terrain** : filtrer `Non validé` → saisir notes → importer conducteurs depuis QR code → fusion.
3. **Préparation commission** : générer PDF multi-conducteurs, exporter CSV pour Excel, synchroniser via iCloud.
4. **Maintenance checklist** : éditer catégories, supprimer question (swipe + confirmation), reimporter version 2026.
5. **Partage sans réseau** : générer QR code d'un conducteur → scanner avec autre appareil → import automatique.
6. **Analyse Excel** : exporter tous les conducteurs en CSV → ouvrir dans Excel → création tableaux croisés dynamiques.

---

## 11. Annexes

- `ARCHITECTURE.md` (dossier référent) pour organigramme complet.
- `FILES_USAGE_REPORT.md` pour traçabilité des fichiers modifiés.
- `Constants.swift` pour les réglages UI (rayons, opacités, seuils).

---

**Dernière révision :** 18 novembre 2025  
**Contact produit :** sylvain.gallon@sncf.fr