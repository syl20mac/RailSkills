# 🔧 Correction - Duplication des fichiers Checklist sur SharePoint

## 🚨 Problème identifié

### Comportement actuel (v2.0)

À chaque modification de la checklist, un **nouveau fichier** est créé sur SharePoint avec un timestamp unique :

```
RailSkills/Checklists/
├── Checklist_CFL_1732460123.json
├── Checklist_CFL_1732460456.json
├── Checklist_CFL_1732460789.json
├── Checklist_CFL_1732461012.json
└── ... (des centaines de fichiers)
```

### Causes du problème

1. **Synchronisation automatique** : Se déclenche à chaque modification de la checklist (ligne 49-50 de `Store.swift`)
2. **Nom unique avec timestamp** : Chaque fichier a un nom unique (ligne 238 de `SharePointSyncService.swift`)
3. **Pas d'écrasement** : Les anciens fichiers ne sont jamais supprimés
4. **Débouncing court** : Délai de seulement 2 secondes entre les synchronisations

### Conséquences

- ❌ **Encombrement SharePoint** : Des centaines/milliers de fichiers identiques
- ❌ **Confusion** : Difficile de savoir quel est le fichier actuel
- ❌ **Performance** : Ralentissement de la synchronisation
- ❌ **Coûts** : Espace de stockage SharePoint gaspillé

## ✅ Solution proposée

### Nouvelle structure (v2.1)

```
RailSkills/Checklists/
├── Checklist_CFL_latest.json          # ← Fichier principal (écrasé)
└── Archives/
    ├── Checklist_CFL_2024-11-24.json  # ← Archive quotidienne
    ├── Checklist_CFL_2024-11-23.json
    └── Checklist_CFL_2024-11-22.json
```

### Changements à implémenter

#### 1. Fichier principal avec écrasement

```swift
// Au lieu de :
let fileName = "\(checklist.title)_\(Int(Date().timeIntervalSince1970)).json"

// Utiliser :
let fileName = "\(checklist.title)_latest.json"
try await uploadFile(
    siteId: siteId,
    fileName: fileName,
    data: data,
    folderPath: checklistsPath,
    overwrite: true  // ← ÉCRASER le fichier existant
)
```

#### 2. Archivage quotidien optionnel

```swift
// Créer une archive SEULEMENT si :
// - C'est une nouvelle journée depuis la dernière archive
// - OU c'est une synchronisation manuelle (bouton)

if shouldCreateArchive {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let dateString = dateFormatter.string(from: Date())
    
    let archiveName = "\(checklist.title)_\(dateString).json"
    try await uploadFile(
        siteId: siteId,
        fileName: archiveName,
        data: data,
        folderPath: "\(checklistsPath)/Archives",
        overwrite: false
    )
}
```

#### 3. Nettoyage automatique des anciennes archives

```swift
// Conserver seulement les 30 dernières archives
func cleanupOldArchives() async throws {
    let maxArchives = 30
    // Supprimer les archives au-delà de maxArchives
}
```

## 🎯 Avantages de la solution

1. **✅ Un seul fichier principal** : Facile à identifier et télécharger
2. **✅ Écrasement automatique** : Toujours la version la plus récente
3. **✅ Archives quotidiennes** : Historique sans duplication
4. **✅ Nettoyage automatique** : Pas d'accumulation infinie
5. **✅ Performance améliorée** : Moins de fichiers à gérer
6. **✅ Rétrocompatible** : Les anciens fichiers restent accessibles

## 📊 Impact estimé

### Avant (v2.0)
- **1 checklist** = 100+ fichiers/jour
- **10 utilisateurs** = 1000+ fichiers/jour
- **1 mois** = 30 000+ fichiers

### Après (v2.1)
- **1 checklist** = 1 fichier principal + 1 archive/jour
- **10 utilisateurs** = 10 fichiers principaux + 10 archives/jour
- **1 mois** = 10 fichiers principaux + 300 archives (avec nettoyage auto)

**Réduction : ~99% de fichiers en moins**

## 🔧 Implémentation recommandée

### Étape 1 : Modifier SharePointSyncService.swift

```swift
func syncChecklist(_ checklist: Checklist, createArchive: Bool = false) async throws {
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
        
        // Convertir en JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(checklist)
        
        let checklistsPath = "RailSkills/Checklists"
        try await ensureFolderExists(siteId: siteId, folderPath: checklistsPath)
        
        // 1. Uploader le fichier principal (AVEC écrasement)
        let mainFileName = "\(sanitizeFileName(checklist.title))_latest.json"
        try await uploadFile(
            siteId: siteId,
            fileName: mainFileName,
            data: data,
            folderPath: checklistsPath,
            overwrite: true  // ← NOUVEAU : écraser le fichier existant
        )
        
        // 2. Créer une archive si demandé ou si nouvelle journée
        if createArchive || shouldCreateDailyArchive() {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: Date())
            
            let archivePath = "\(checklistsPath)/Archives"
            try await ensureFolderExists(siteId: siteId, folderPath: archivePath)
            
            let archiveName = "\(sanitizeFileName(checklist.title))_\(dateString).json"
            try await uploadFile(
                siteId: siteId,
                fileName: archiveName,
                data: data,
                folderPath: archivePath,
                overwrite: true  // Écraser si déjà synchronisé aujourd'hui
            )
            
            lastArchiveDate = Date()
        }
        
        lastSyncDate = Date()
        syncError = nil
        
        Logger.success("Checklist '\(checklist.title)' synchronisée vers SharePoint", category: "SharePointSync")
    } catch {
        syncError = error.localizedDescription
        Logger.error("Erreur synchronisation checklist: \(error.localizedDescription)", category: "SharePointSync")
        throw error
    }
}

private func shouldCreateDailyArchive() -> Bool {
    guard let lastArchive = lastArchiveDate else { return true }
    
    let calendar = Calendar.current
    return !calendar.isDate(lastArchive, inSameDayAs: Date())
}

private func sanitizeFileName(_ name: String) -> String {
    return name
        .replacingOccurrences(of: " ", with: "_")
        .replacingOccurrences(of: "/", with: "-")
        .replacingOccurrences(of: "\\", with: "-")
}
```

### Étape 2 : Ajouter un paramètre de configuration

```swift
// Dans SharePointSyncService
@AppStorage("sharePointArchiveMode") var archiveMode: ArchiveMode = .daily

enum ArchiveMode: String, Codable {
    case none       // Pas d'archive, seulement le fichier principal
    case daily      // Une archive par jour
    case weekly     // Une archive par semaine
    case monthly    // Une archive par mois
    case always     // Toujours archiver (comportement actuel)
}
```

### Étape 3 : Ajouter une interface de configuration

Dans `SharePointSyncView.swift`, ajouter :

```swift
Section {
    Picker("Mode d'archivage", selection: $sharePointService.archiveMode) {
        Text("Aucun (fichier principal seulement)").tag(ArchiveMode.none)
        Text("Quotidien (recommandé)").tag(ArchiveMode.daily)
        Text("Hebdomadaire").tag(ArchiveMode.weekly)
        Text("Mensuel").tag(ArchiveMode.monthly)
        Text("Toujours (comportement actuel)").tag(ArchiveMode.always)
    }
} header: {
    Text("Configuration des archives")
} footer: {
    Text("Contrôle la fréquence de création des archives. Le fichier principal est toujours mis à jour.")
}
```

## 🧹 Script de nettoyage (optionnel)

Pour nettoyer les fichiers existants sur SharePoint :

```swift
func cleanupDuplicateChecklists() async throws {
    let siteId = try await getSiteId()
    let checklistsPath = "RailSkills/Checklists"
    
    // 1. Lister tous les fichiers
    let files = try await listFiles(siteId: siteId, folderPath: checklistsPath)
    
    // 2. Grouper par nom de checklist (sans timestamp)
    var groups: [String: [SharePointFile]] = [:]
    for file in files {
        let baseName = extractBaseName(from: file.name)
        groups[baseName, default: []].append(file)
    }
    
    // 3. Pour chaque groupe, garder le plus récent et supprimer les autres
    for (baseName, files) in groups {
        let sortedFiles = files.sorted { $0.lastModified > $1.lastModified }
        
        // Renommer le plus récent en "_latest"
        if let latest = sortedFiles.first {
            let newName = "\(baseName)_latest.json"
            try await renameFile(siteId: siteId, fileId: latest.id, newName: newName)
        }
        
        // Supprimer ou déplacer les autres vers Archives
        for oldFile in sortedFiles.dropFirst() {
            // Option 1 : Supprimer
            // try await deleteFile(siteId: siteId, fileId: oldFile.id)
            
            // Option 2 : Déplacer vers Archives
            try await moveToArchive(siteId: siteId, file: oldFile)
        }
    }
}
```

## 📝 Migration recommandée

1. **Phase 1** : Déployer la nouvelle version avec le mode "daily" par défaut
2. **Phase 2** : Informer les utilisateurs du changement
3. **Phase 3** : Après 1 semaine, exécuter le script de nettoyage
4. **Phase 4** : Mettre en place le nettoyage automatique des anciennes archives

## ⚠️ Points d'attention

1. **Rétrocompatibilité** : Les anciens fichiers restent accessibles
2. **Import** : Adapter l'import pour chercher d'abord les fichiers "_latest"
3. **Web App** : Mettre à jour RailSkills-Web pour la nouvelle structure
4. **Tests** : Tester la synchronisation avec plusieurs utilisateurs
5. **Documentation** : Mettre à jour SHAREPOINT_INTEGRATION.md

---

**Date :** 24 novembre 2024  
**Version cible :** RailSkills v2.1  
**Priorité :** 🔴 Haute (impact sur les coûts SharePoint)



