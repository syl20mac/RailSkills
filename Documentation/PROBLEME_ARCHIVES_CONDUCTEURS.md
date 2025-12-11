# 🔍 Problème : 3 fichiers JSON par conducteur

## 📊 Situation actuelle

Chaque conducteur génère **plusieurs fichiers** sur SharePoint :

### Exemple pour "Jean Dupont"

```
CTT_jean.dupont/Data/Jean_Dupont/
├── Jean_Dupont.json                 # ← Fichier principal (écrasé)
├── Jean_Dupont_1732460123.json     # ← Archive 1 (synchronisation 1)
├── Jean_Dupont_1732460456.json     # ← Archive 2 (synchronisation 2)
└── Jean_Dupont_1732460789.json     # ← Archive 3 (synchronisation 3)
```

Si vous voyez **3 fichiers**, c'est que :
- 1 fichier principal
- 2 archives (2 synchronisations effectuées)

Si vous voyez **plus de 3 fichiers**, c'est que plusieurs synchronisations ont eu lieu.

## 🐛 Cause du problème

### Code actuel (lignes 130-148)

```swift
// 1. Sauvegarder le fichier principal (ÉCRASÉ à chaque fois)
try await uploadFile(
    siteId: siteId,
    fileName: "\(folderName).json",      // Jean_Dupont.json
    data: data,
    folderPath: driverFolderPath,
    overwrite: true                       // ← ÉCRASE l'ancien
)

// 2. Sauvegarder UNE ARCHIVE avec timestamp (CRÉÉ à chaque fois)
let timestamp = Int(Date().timeIntervalSince1970)
let archiveFileName = "\(folderName)_\(timestamp).json"  // Jean_Dupont_1732460123.json
try await uploadFile(
    siteId: siteId,
    fileName: archiveFileName,
    data: data,
    folderPath: driverFolderPath,
    overwrite: false                      // ← NOUVEAU FICHIER à chaque fois
)
```

### Conséquence

**À CHAQUE synchronisation** (automatique ou manuelle) :
- ✅ Le fichier principal est **mis à jour** (1 seul fichier)
- ❌ Une **nouvelle archive** est créée (accumulation infinie !)

## 📈 Impact

### Scénario réel

- **Synchronisation automatique** : Toutes les 2 secondes après modification
- **Modifications fréquentes** : Ajout de notes, changement d'état checklist
- **1 conducteur** avec 10 modifications/jour = 10 archives/jour
- **20 conducteurs** = 200 archives/jour
- **1 mois** = 6 000 archives !

### Problèmes

❌ **Encombrement SharePoint** : Des milliers de fichiers identiques  
❌ **Performance** : SharePoint ralentit avec trop de fichiers  
❌ **Confusion** : Quel est le bon fichier ?  
❌ **Coûts** : Espace de stockage gaspillé  
❌ **Maintenance** : Difficile de nettoyer

## ✅ Solutions proposées

### Option 1 : Supprimer les archives automatiques (RECOMMANDÉ)

**Garder SEULEMENT le fichier principal.**

#### Avantages
✅ 1 seul fichier par conducteur  
✅ Simple et clair  
✅ Pas d'accumulation  
✅ Fichier toujours à jour

#### Inconvénients
⚠️ Pas d'historique automatique  
⚠️ Impossible de revenir en arrière

#### Code modifié

```swift
// Sauvegarder SEULEMENT le fichier principal
try await uploadFile(
    siteId: siteId,
    fileName: fileName,
    data: data,
    folderPath: driverFolderPath,
    overwrite: true
)

// SUPPRIMER : La création d'archive automatique
// let timestamp = Int(Date().timeIntervalSince1970)
// let archiveFileName = "\(folderName)_\(timestamp).json"
// ...
```

---

### Option 2 : Archives quotidiennes uniquement

**Une seule archive par jour maximum.**

#### Avantages
✅ Historique disponible  
✅ Limité (30 archives/conducteur/mois max)  
✅ Permet de revenir en arrière

#### Code modifié

```swift
// 1. Fichier principal
try await uploadFile(
    siteId: siteId,
    fileName: fileName,
    data: data,
    folderPath: driverFolderPath,
    overwrite: true
)

// 2. Archive quotidienne (SEULEMENT si nouvelle journée)
if shouldCreateDailyArchive(for: driver.id) {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let dateString = dateFormatter.string(from: Date())
    
    let archiveFileName = "\(folderName)_\(dateString).json"
    try await uploadFile(
        siteId: siteId,
        fileName: archiveFileName,
        data: data,
        folderPath: driverFolderPath,
        overwrite: true  // ← Écrase l'archive du jour si existe
    )
    
    markArchiveCreated(for: driver.id, date: Date())
}
```

---

### Option 3 : Archives sur demande uniquement

**Créer des archives SEULEMENT lors de synchronisations manuelles.**

#### Avantages
✅ Contrôle total  
✅ Archives importantes seulement  
✅ Pas d'accumulation automatique

#### Code modifié

```swift
func syncDrivers(_ drivers: [DriverRecord], createArchive: Bool = false) async throws {
    // ...
    
    // Fichier principal
    try await uploadFile(...)
    
    // Archive SEULEMENT si demandé explicitement
    if createArchive {
        let timestamp = Int(Date().timeIntervalSince1970)
        let archiveFileName = "\(folderName)_\(timestamp).json"
        try await uploadFile(...)
    }
}
```

---

### Option 4 : Archives avec rotation

**Garder seulement les N dernières archives.**

#### Avantages
✅ Historique limité  
✅ Nettoyage automatique  
✅ Espace maîtrisé

#### Code modifié

```swift
// Après création d'une nouvelle archive
await cleanupOldArchives(
    siteId: siteId,
    folderPath: driverFolderPath,
    baseName: folderName,
    keepCount: 5  // Garder seulement les 5 dernières
)
```

---

## 🎯 Recommandation

**Pour RailSkills, je recommande l'Option 1 : Supprimer les archives automatiques**

### Justification

1. **Simplicité** : 1 fichier = 1 conducteur
2. **Performance** : Pas d'accumulation
3. **Clarté** : Toujours le bon fichier
4. **Sécurité** : Le fichier principal est toujours à jour
5. **Historique** : L'application iPad garde déjà l'historique local

### Système d'historique existant

L'application RailSkills **garde déjà un historique local** :
- UserDefaults + iCloud
- Sauvegarde automatique
- Historique des modifications

**SharePoint = Backup central**, pas besoin d'historique supplémentaire.

---

## 🔧 Implémentation recommandée

### Modification à faire

**Fichier** : `Services/SharePointSyncService.swift`  
**Lignes** : 139-148

```swift
// SUPPRIMER ces lignes :
// Sauvegarder aussi une archive avec timestamp
let timestamp = Int(Date().timeIntervalSince1970)
let archiveFileName = "\(folderName)_\(timestamp).json"
try await uploadFile(
    siteId: siteId,
    fileName: archiveFileName,
    data: data,
    folderPath: driverFolderPath,
    overwrite: false
)
```

### Résultat

Chaque conducteur aura **EXACTEMENT 1 fichier** :

```
CTT_jean.dupont/Data/Jean_Dupont/
└── Jean_Dupont.json     # ← Un seul fichier, toujours à jour
```

---

## 🧹 Nettoyage des archives existantes

### Script de nettoyage (optionnel)

Pour supprimer les archives existantes et garder seulement les fichiers principaux :

```swift
func cleanupDriverArchives() async throws {
    let siteId = try await getSiteId()
    let cttFolder = getCTTFolderName()
    let basePath = "RailSkills/CTT_\(cttFolder)/Data"
    
    // Pour chaque dossier conducteur
    let folders = try await listFolders(siteId: siteId, path: basePath)
    
    for folderName in folders {
        let files = try await listFiles(
            siteId: siteId,
            path: "\(basePath)/\(folderName)"
        )
        
        // Supprimer tous les fichiers SAUF le fichier principal
        for file in files {
            if file.name != "\(folderName).json" {
                try await deleteFile(siteId: siteId, fileId: file.id)
                Logger.info("Archive supprimée: \(file.name)", category: "SharePointSync")
            }
        }
    }
}
```

---

## 📊 Comparaison des options

| Critère | Option 1 | Option 2 | Option 3 | Option 4 |
|---------|----------|----------|----------|----------|
| **Simplicité** | ✅✅✅ | ✅✅ | ✅✅ | ⚠️ |
| **Espace disque** | ✅✅✅ | ✅✅ | ✅✅✅ | ✅✅ |
| **Historique** | ❌ | ✅ | ✅ | ✅ |
| **Complexité** | ✅ Simple | ⚠️ Moyenne | ✅ Simple | ❌ Complexe |
| **Maintenance** | ✅ Aucune | ✅ Auto | ✅ Aucune | ⚠️ Nécessaire |
| **Recommandé** | ✅ | ⚠️ | ⚠️ | ❌ |

---

## 🎯 Décision

**Voulez-vous que j'implémente l'Option 1 maintenant ?**

- ✅ Suppression des archives automatiques
- ✅ 1 seul fichier par conducteur
- ✅ Toujours à jour
- ✅ Simple et efficace

Ou préférez-vous une autre option ?

---

**Date** : 24 novembre 2024  
**Version** : RailSkills v2.1  
**Priorité** : 🔴 Haute (même problème que les checklists)



