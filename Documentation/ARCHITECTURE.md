# Architecture RailSkills v2.0

## 📁 Structure des dossiers

```
RailSkills/
├── Models/                          # Modèles de données
│   ├── ChecklistItem.swift
│   ├── Checklist.swift
│   ├── DriverRecord.swift
│   └── ShareableDriverRecord.swift
│
├── Services/                        # Services métier
│   ├── Store.swift                  # Persistance des données (UserDefaults)
│   ├── ChecklistParser.swift       # Analyse et import de checklists
│   ├── PDFReportGenerator.swift    # Génération de rapports PDF
│   ├── QRCodeService.swift         # Génération et lecture de QR codes
│   ├── ExportService.swift         # Export/Import JSON avec compression
│   └── SharePointSyncService.swift # Synchronisation Backend/SharePoint
│
├── ViewModels/                      # ViewModels (logique métier)
│   ├── AppViewModel.swift          # ViewModel principal
│   └── DriversViewModel.swift      # Gestion des conducteurs
│
├── Views/                           # Vues SwiftUI
│   ├── ContentView.swift           # Vue principale
│   ├── Drivers/
│   │   ├── DriversManagerView.swift
│   │   └── AddDriverSheet.swift
│   ├── Checklist/
│   │   ├── ChecklistEditorView.swift
│   │   ├── ChecklistRow.swift
│   │   └── ChecklistSection.swift
│   ├── Suivi/
│   │   ├── StateInteractionView.swift
│   │   ├── QuadStateToggle.swift
│   │   ├── SegmentedStateControl.swift
│   │   ├── ButtonsStateControl.swift
│   │   ├── MenuStateControl.swift
│   │   └── NoteEditorSheet.swift
│   ├── Sharing/
│   │   └── SharingView.swift
│   ├── Reports/
│   │   └── ReportsView.swift
│   └── Settings/
│       └── SettingsView.swift
│
├── Utilities/                       # Utilitaires
│   ├── DateFormatHelper.swift
│   ├── MergeStrategy.swift
│   ├── ImportResult.swift
│   ├── InteractionMode.swift
│   └── Extensions.swift            # Extensions Color, Data, View
│
└── RailSkillsApp.swift             # Point d'entrée de l'application
```

## 🏗️ Architecture MVVM

### Pattern de séparation des responsabilités

```
┌─────────────────────────────────────────────────────────────┐
│                        View Layer                            │
│  (SwiftUI Views - Pas de logique métier)                    │
├─────────────────────────────────────────────────────────────┤
│                      ViewModel Layer                         │
│  (Combine - Gestion d'état, transformations)                │
├─────────────────────────────────────────────────────────────┤
│                       Service Layer                          │
│  (Store, Parser, Export, QR, PDF)                           │
├─────────────────────────────────────────────────────────────┤
│                        Model Layer                           │
│  (Codable - Structures de données)                          │
└─────────────────────────────────────────────────────────────┘
```

## 📋 Responsabilités par couche

### Models/
- Structures de données pures (Codable)
- Aucune logique métier
- Identifiables et Hashables quand nécessaire

### Services/
- **Store** : Persistance UserDefaults, sauvegarde automatique avec débouncing
- **ChecklistParser** : Parsing de texte Markdown en checklist structurée
- **PDFReportGenerator** : Génération de rapports PDF avec en-têtes
- **QRCodeService** : Génération et lecture de QR codes (CoreImage)
- **ExportService** : Export/Import JSON avec compression LZFSE
- **SharePointSyncService** : Synchronisation des données avec SharePoint via le Backend (Checklists & Conducteurs)

### ViewModels/
- Logique de présentation
- Transformation des données pour les vues
- Gestion d'état avec Combine (@Published)
- Validation et règles métier

### Views/
- Interface utilisateur pure (SwiftUI)
- Responsive (iPad/iPhone)
- Navigation adaptative (NavigationSplitView/NavigationStack)
- Composants réutilisables

### Utilities/
- Extensions Swift
- Helpers et utilitaires
- Enums et types support

## 🔄 Flux de données

1. **Lecture** : View → ViewModel → Service → Model → UserDefaults
2. **Écriture** : View → ViewModel → Service → UserDefaults (avec débouncing)
3. **Synchro** : SharePointSyncService ↔ Backend API ↔ SharePoint → Store
4. **Export** : ViewModel → ExportService → QRCodeService → View
5. **Import** : View → ExportService → ViewModel → Service → UserDefaults

## 🎯 Principes de conception

- **Séparation des responsabilités** : Chaque couche a un rôle clair
- **Testabilité** : Services et ViewModels testables indépendamment
- **Maintenabilité** : Code organisé et modulaire
- **Évolutivité** : Facile d'ajouter de nouvelles fonctionnalités
- **Réutilisabilité** : Composants et services réutilisables

## 📱 Adaptation iPad/iPhone

- NavigationSplitView sur iPad (sidebar + detail)
- NavigationStack sur iPhone
- Composants adaptatifs (compact/large)
- Toolbars contextuelles




