# 📁 Structure SharePoint - Segmentation par Manager Traction

## 🔍 Situation actuelle

### Ancienne structure (v1.x avec SNCF_ID)

Les conducteurs étaient organisés par **dossier Manager Traction** :

```
SharePoint/RailSkills/
├── CTT_jean.dupont@sncf.fr/
│   └── Data/
│       ├── Conducteur_A/
│       ├── Conducteur_B/
│       └── Conducteur_C/
├── CTT_marie.martin@sncf.fr/
│   └── Data/
│       ├── Conducteur_D/
│       └── Conducteur_E/
└── ...
```

**✅ Avantages** :
- Chaque Manager Traction a son propre espace
- Séparation claire des responsabilités
- Facile de voir qui gère quels conducteurs

**❌ Inconvénients** :
- Duplication si un conducteur change de Manager Traction
- Complexe pour les rapports globaux
- Nécessite SNCF_ID (supprimé depuis)

### Structure actuelle (v2.0 sans SNCF_ID)

Tous les conducteurs sont dans un **dossier partagé global** :

```
SharePoint/RailSkills/
└── Data/
    ├── Conducteur_A/
    ├── Conducteur_B/
    ├── Conducteur_C/
    ├── Conducteur_D/
    └── Conducteur_E/
```

**✅ Avantages** :
- Structure simplifiée
- Pas de duplication
- Facile pour les rapports globaux
- Ne nécessite pas SNCF_ID

**❌ Inconvénients** :
- Pas de séparation par Manager Traction
- Tous les conducteurs au même niveau
- Difficile de voir qui gère quoi

## ❓ Pourquoi ce changement ?

Le système **SNCF_ID** (authentification via le SDK SNCF) a été supprimé car :
1. ⚠️ SDK non encore intégré dans l'application
2. 🔧 Complexité technique
3. 🎯 Besoin de simplifier pour le MVP

Sans identité Manager Traction automatique, on ne pouvait plus créer les dossiers `CTT_{sncfId}/` (note: `CTT_` est un préfixe technique)

## 💡 Solutions proposées

### Option 1 : Réintroduire la segmentation par Manager Traction (recommandé)

Utiliser le **profil Manager Traction manuel** au lieu de SNCF_ID.

#### Structure proposée

```
SharePoint/RailSkills/
├── CTT_Jean_Dupont/
│   └── Data/
│       ├── Conducteur_A/
│       └── Conducteur_B/
├── CTT_Marie_Martin/
│   └── Data/
│       ├── Conducteur_C/
│       └── Conducteur_D/
└── Shared/              # ← Dossier partagé optionnel
    └── Data/
        └── (conducteurs non attribués)
```

#### Implémentation

**1. Ajouter un profil CTT dans l'app**

```swift
// Dans Store.swift
@AppStorage("cttName") var cttName: String = ""
@AppStorage("cttOrganization") var cttOrganization: String = ""

var cttIdentifier: String {
    if !cttName.isEmpty {
        return sanitizeFolderName(cttName)
    }
    // Fallback sur le nom de l'appareil
    return UIDevice.current.name.replacingOccurrences(of: " ", with: "_")
}
```

**2. Modifier SharePointSyncService.swift**

```swift
func syncDrivers(_ drivers: [DriverRecord]) async throws {
    guard isConfigured else {
        throw SharePointSyncError.notConfigured
    }
    
    isSyncing = true
    syncError = nil
    
    defer {
        isSyncing = false
    }
    
    do {
        let siteId = try await getSiteId()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        // 🆕 NOUVEAU : Segmentation par Manager Traction
        // Note: cttFolder et CTT_ sont des identifiants techniques
        let cttFolder = Store.shared.cttIdentifier
        let basePath = "RailSkills/CTT_\(cttFolder)/Data"
        
        // S'assurer que le dossier parent existe
        try await ensureFolderExists(siteId: siteId, folderPath: basePath)
        
        var successCount = 0
        var errors: [String] = []
        
        // Synchroniser chaque conducteur
        for driver in drivers {
            do {
                let sanitizedName = sanitizeFolderName(driver.name)
                let folderName = sanitizedName.isEmpty ? driver.id.uuidString : sanitizedName
                let driverFolderPath = "\(basePath)/\(folderName)"
                
                Logger.info("Synchronisation '\(driver.name)' dans dossier Manager Traction (CTT_\(cttFolder))", category: "SharePointSync")
                
                try await ensureFolderExists(siteId: siteId, folderPath: driverFolderPath)
                let data = try encoder.encode(driver)
                let fileName = "\(folderName).json"
                
                try await uploadFile(
                    siteId: siteId,
                    fileName: fileName,
                    data: data,
                    folderPath: driverFolderPath,
                    overwrite: true
                )
                
                successCount += 1
            } catch {
                let errorMsg = "Erreur pour '\(driver.name)': \(error.localizedDescription)"
                errors.append(errorMsg)
                Logger.warning(errorMsg, category: "SharePointSync")
            }
        }
        
        if !errors.isEmpty {
            syncError = "\(errors.count) erreur(s): \(errors.joined(separator: "; "))"
        } else {
            syncError = nil
        }
        
        lastSyncDate = Date()
        Logger.success("\(successCount)/\(drivers.count) conducteur(s) synchronisé(s) vers SharePoint (CTT_\(cttFolder))", category: "SharePointSync")
    } catch {
        syncError = error.localizedDescription
        Logger.error("Erreur synchronisation conducteurs: \(error.localizedDescription)", category: "SharePointSync")
        throw error
    }
}
```

**3. Ajouter l'interface de configuration**

Dans `SettingsView.swift`, ajouter une nouvelle section :

```swift
Section {
    TextField("Nom du CTT", text: $store.cttName)
        .autocorrectionDisabled()
    
    TextField("Organisation", text: $store.cttOrganization)
        .autocorrectionDisabled()
    
    if !store.cttName.isEmpty {
        HStack {
            Text("Dossier SharePoint")
                .foregroundStyle(.secondary)
            Spacer()
            Text("CTT_\(store.cttIdentifier)")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(SNCFColors.ceruleen)
        }
    }
} header: {
    Text("Profil Manager Traction")
} footer: {
    Text("Les conducteurs seront synchronisés dans votre dossier Manager Traction personnel sur SharePoint. Si vide, le nom de l'appareil sera utilisé.")
}
```

#### Avantages de cette solution

✅ Chaque Manager Traction a son dossier sur SharePoint  
✅ Séparation claire des responsabilités  
✅ Compatible avec l'architecture actuelle (pas de SNCF_ID)  
✅ Configuration simple et intuitive  
✅ Rétrocompatible (peut lire l'ancienne structure globale)

---

### Option 2 : Garder la structure globale + métadonnées

Garder tous les conducteurs au même endroit, mais ajouter un champ `ownerCTT` dans les données.

#### Avantages

✅ Structure simple  
✅ Pas de modification majeure du code  
✅ Facile pour les rapports globaux

#### Inconvénients

❌ Pas de séparation physique des dossiers  
❌ Tous les Manager Traction voient tous les conducteurs  
❌ Moins clair visuellement

---

### Option 3 : Hybride (recommandé pour grande organisation)

Combiner les deux approches :

```
SharePoint/RailSkills/
├── CTT_Jean_Dupont/          # Conducteurs gérés par Jean
│   └── Data/
├── CTT_Marie_Martin/         # Conducteurs gérés par Marie
│   └── Data/
├── Shared/                   # Conducteurs partagés ou transférés
│   └── Data/
└── Archives/                 # Anciennes données (cleanup auto)
    └── CTT_*/
```

---

## 🚀 Migration recommandée

### Étape 1 : Configurer le profil CTT

Pour chaque utilisateur de l'app :
1. Ouvrir Réglages → Profil CTT
2. Saisir son nom (ex: "Jean Dupont")
3. Saisir son organisation (ex: "SNCF Traction Île-de-France")

### Étape 2 : Déployer la nouvelle version

- Les nouveaux conducteurs iront dans `CTT_{nom}/Data/`
- L'ancienne structure globale reste accessible en lecture

### Étape 3 : Script de migration (optionnel)

```swift
// Migrer les conducteurs existants vers les dossiers CTT
func migrateToPerCTTStructure() async throws {
    // 1. Lire tous les conducteurs du dossier global
    let globalDrivers = try await readDriversFromPath("RailSkills/Data")
    
    // 2. Pour chaque conducteur, demander à quel CTT il appartient
    // 3. Copier vers le bon dossier CTT
    // 4. Supprimer de l'ancien emplacement
}
```

---

## 📊 Comparaison des options

| Critère | Option 1 (CTT) | Option 2 (Global) | Option 3 (Hybride) |
|---------|----------------|-------------------|-------------------|
| **Séparation claire** | ✅ Excellente | ❌ Aucune | ✅ Excellente |
| **Simplicité** | ✅ Simple | ✅ Très simple | ⚠️ Moyenne |
| **Rapports globaux** | ⚠️ Plus complexe | ✅ Facile | ✅ Facile |
| **Évolutivité** | ✅ Bonne | ⚠️ Limitée | ✅ Excellente |
| **Migration** | ⚠️ Nécessaire | ✅ Aucune | ⚠️ Nécessaire |
| **Recommandé pour** | Petite org | MVP/Test | Grande org |

---

## 🎯 Recommandation finale

**Pour RailSkills v2.1, je recommande l'Option 1** :

1. ✅ Segmentation par dossier CTT
2. ✅ Configuration manuelle simple (nom CTT)
3. ✅ Pas besoin de SNCF_ID
4. ✅ Structure claire et professionnelle
5. ✅ Facilite la gestion et l'audit

### Prochaines étapes

1. **Valider l'approche** avec les utilisateurs finaux (CTT)
2. **Implémenter** les modifications dans `SharePointSyncService.swift`
3. **Ajouter** l'interface de configuration du profil CTT
4. **Tester** avec plusieurs CTT sur le même SharePoint
5. **Documenter** la nouvelle structure
6. **Déployer** progressivement

---

**Date :** 24 novembre 2024  
**Version cible :** RailSkills v2.1  
**Priorité :** 🟡 Moyenne (amélioration structurelle)



