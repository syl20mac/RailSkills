# ✅ Solution : Dossiers Manager Traction sur SharePoint

## 🎯 Problème résolu

Le Manager Traction s'authentifie au lancement de l'app avec son **email et mot de passe**.  
Le serveur retourne un `UserProfile` contenant le **`cttId`** (identifiant technique).

## 📊 Structure `UserProfile` existante

```swift
struct UserProfile: Codable {
    let id: String          // ID utilisateur
    let email: String       // Email du CTT
    let cttId: String       // ← IDENTIFIANT DU CTT !
    let createdAt: String?
    let lastLogin: String?
}
```

Le `WebAuthService.shared.currentUser?.cttId` contient l'identifiant unique du Manager Traction.

## 🔧 Solution à implémenter

### Étape 1 : Modifier SharePointSyncService

Utiliser le `cttId` de l'utilisateur connecté pour créer la structure de dossiers :

```swift
// Dans SharePointSyncService.swift, ligne 94-98

// AVANT (structure globale)
let basePath = "RailSkills/Data"

// APRÈS (structure par CTT)
let cttFolder = getCTTFolderName()
let basePath = "RailSkills/CTT_\(cttFolder)/Data"
```

### Étape 2 : Ajouter la fonction pour récupérer le CTT

```swift
// Dans SharePointSyncService.swift

/// Récupère le nom du dossier CTT depuis l'utilisateur connecté
/// - Returns: Le nom du dossier CTT (ex: "Jean_Dupont" ou "Shared")
private func getCTTFolderName() -> String {
    // 1. Essayer de récupérer depuis WebAuthService (authentification web)
    if let currentUser = WebAuthService.shared.currentUser,
       !currentUser.cttId.isEmpty {
        return sanitizeFolderName(currentUser.cttId)
    }
    
    // 2. Fallback : utiliser le nom de l'appareil (mode développement)
    #if DEBUG
    return "Dev_iPad"
    #else
    return "Shared"
    #endif
}
```

### Étape 3 : Appliquer aussi aux checklists

Même logique pour les checklists (ligne 232) :

```swift
// AVANT
let checklistsPath = "RailSkills/Checklists"

// APRÈS
let cttFolder = getCTTFolderName()
let checklistsPath = "RailSkills/CTT_\(cttFolder)/Checklists"
```

## 📁 Nouvelle structure SharePoint

```
SharePoint/RailSkills/
├── CTT_jean.dupont/
│   ├── Data/
│   │   ├── Conducteur_A/
│   │   └── Conducteur_B/
│   └── Checklists/
│       └── Checklist_CFL_latest.json
├── CTT_marie.martin/
│   ├── Data/
│   │   ├── Conducteur_C/
│   │   └── Conducteur_D/
│   └── Checklists/
│       └── Checklist_CFL_latest.json
└── Shared/               # Mode développement ou non connecté
    ├── Data/
    └── Checklists/
```

## 🎨 Code complet à implémenter

Je vais créer le patch complet maintenant ?

**Voulez-vous que j'implémente cette solution maintenant ?**

- ✅ Utilise le `cttId` déjà présent dans `UserProfile`
- ✅ Pas besoin de nouvelle configuration
- ✅ Fonctionne automatiquement après login
- ✅ Fallback en mode développement
- ✅ Compatible avec l'existant

---

**Estimation** : 10 minutes d'implémentation
**Impact** : Segmentation automatique par CTT sur SharePoint



