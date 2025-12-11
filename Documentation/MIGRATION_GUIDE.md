# Guide de migration vers l'architecture modulaire

## 📋 Vue d'ensemble

Cette architecture modulaire sépare le code monolithique de `ContentView.swift` (4025 lignes) en modules clairs et maintenables selon le pattern **MVVM**.

## ✅ Ce qui a été créé

### 📁 Structure de dossiers

```
RailSkills/
├── Models/                          ✅ Créé
│   ├── ChecklistItem.swift
│   ├── Checklist.swift
│   ├── DriverRecord.swift
│   └── ShareableDriverRecord.swift
│
├── Services/                        ✅ Créé
│   ├── Store.swift                  # Persistance UserDefaults
│   ├── ChecklistParser.swift       # Parsing de checklists
│   ├── PDFReportGenerator.swift    # Génération PDF
│   ├── QRCodeService.swift         # Génération QR codes
│   └── ExportService.swift         # Export/Import JSON
│
├── ViewModels/                      ✅ Créé
│   └── AppViewModel.swift          # ViewModel principal
│
└── Utilities/                       ✅ Créé
    ├── DateFormatHelper.swift
    ├── MergeStrategy.swift
    ├── ImportResult.swift
    ├── InteractionMode.swift
    └── Extensions.swift            # Extensions Color, Data, View
```

## 🔄 Prochaines étapes

### 1. Ajouter les fichiers au projet Xcode

1. Ouvrez Xcode
2. Faites un clic droit sur le dossier `RailSkills` dans le navigateur de projet
3. Sélectionnez "Add Files to RailSkills..."
4. Sélectionnez tous les nouveaux dossiers (`Models`, `Services`, `ViewModels`, `Utilities`)
5. Cochez "Create groups" (pas "Create folder references")
6. Cochez "Copy items if needed" si nécessaire
7. Assurez-vous que la cible "RailSkills" est sélectionnée

### 2. Mettre à jour ContentView.swift

Dans `ContentView.swift`, vous devez :

1. **Remplacer les imports** : Ajouter les imports nécessaires en haut du fichier
2. **Remplacer `ViewModel` par `AppViewModel`** : Tous les `ViewModel()` doivent devenir `AppViewModel()`
3. **Supprimer les définitions de modèles** : Supprimer les structs `ChecklistItem`, `Checklist`, `DriverRecord`, `ShareableDriverRecord` (maintenant dans Models/)
4. **Supprimer la classe Store** : Supprimer la définition de `Store` (maintenant dans Services/)
5. **Supprimer les enums et helpers** : Supprimer `ChecklistParser`, `DateFormatHelper`, `PDFReportGenerator`, `MergeStrategy`, `ImportResult`, `InteractionMode`, et les extensions (maintenant dans leurs fichiers respectifs)

### 3. Mettre à jour RailSkillsApp.swift

Si vous utilisez SwiftData, vous pouvez maintenant supprimer la référence à `Item` qui n'est plus utilisée :

```swift
// Supprimer ces lignes si Item n'est plus utilisé
let schema = Schema([
    Item.self,
])
```

### 4. Vérifier les imports

Assurez-vous que tous les fichiers importent correctement :
- `Foundation` pour les modèles
- `SwiftUI` pour les vues
- `Combine` pour les ViewModels
- `CoreImage` / `UIKit` pour les services QR et PDF

## 🐛 Correction des erreurs potentielles

### Erreur : "Cannot find 'ViewModel' in scope"

**Solution** : Remplacer `ViewModel` par `AppViewModel` dans toutes les vues.

### Erreur : "Cannot find type 'ChecklistItem'"

**Solution** : Vérifier que les fichiers dans `Models/` sont bien ajoutés au target dans Xcode.

### Erreur : "Value of type 'AppViewModel' has no member 'store'"

**Solution** : `AppViewModel` contient bien `store`, vérifiez que le fichier `ViewModels/AppViewModel.swift` est compilé.

## 📝 Notes importantes

1. **Le code existant dans ContentView.swift reste fonctionnel** : Vous pouvez migrer progressivement
2. **Les données sont préservées** : La persistance UserDefaults reste identique
3. **Aucune breaking change** : L'API publique des ViewModels reste la même
4. **Performance améliorée** : Le système de cache est conservé dans AppViewModel

## 🎯 Bénéfices de cette architecture

✅ **Séparation des responsabilités** : Chaque module a un rôle clair  
✅ **Maintenabilité** : Code plus facile à comprendre et modifier  
✅ **Testabilité** : Services et ViewModels testables indépendamment  
✅ **Réutilisabilité** : Composants réutilisables dans d'autres projets  
✅ **Évolutivité** : Facile d'ajouter de nouvelles fonctionnalités  

## 📚 Documentation

Consultez `ARCHITECTURE.md` pour plus de détails sur l'architecture et les principes de conception.

## ❓ Besoin d'aide ?

Si vous rencontrez des problèmes lors de la migration, vérifiez :
1. Que tous les fichiers sont bien ajoutés au target Xcode
2. Que les imports sont corrects
3. Que les noms de classes/types correspondent (ViewModel → AppViewModel)






