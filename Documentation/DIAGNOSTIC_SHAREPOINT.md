# 🔍 Diagnostic : Dossiers SharePoint non créés

**Date :** 26 novembre 2025  
**Problème :** Les conducteurs présents sur l'iPad n'ont pas créé de dossiers sur SharePoint

---

## 📊 Analyse du problème

### ✅ Ce qui est implémenté

1. **Synchronisation automatique activée par défaut**
   ```swift
   // Services/Store.swift (ligne 19)
   @AppStorage("sharePointAutoSyncEnabled") var sharePointAutoSyncEnabled: Bool = true
   ```

2. **Déclenchement automatique lors des modifications**
   ```swift
   // Services/Store.swift (lignes 34-36)
   if sharePointAutoSyncEnabled && sharePointService.isConfigured && !drivers.isEmpty {
       syncDriversToSharePointDebounced()
   }
   ```

3. **Structure des dossiers CTT configurée**
   ```swift
   // SharePointSyncService.swift (lignes 98-99)
   let cttFolder = getCTTFolderName()  // Récupère le cttId de l'utilisateur connecté
   let basePath = "RailSkills/CTT_\(cttFolder)/Data"
   ```

---

## ❌ Pourquoi la synchronisation ne fonctionne pas

### Condition manquante : `sharePointService.isConfigured`

La synchronisation SharePoint ne se déclenche **QUE** si :

```swift
sharePointAutoSyncEnabled          // ✅ TRUE par défaut
&&
sharePointService.isConfigured     // ❌ FALSE (Azure AD non configuré)
&&
!drivers.isEmpty                   // ✅ TRUE (vous avez des conducteurs)
```

### Vérification de `isConfigured`

```swift
// SharePointSyncService.swift (lignes 29-31)
var isConfigured: Bool {
    return azureADService.isConfigured
}
```

### Ce qui est vérifié dans Azure AD

```swift
// Services/AzureADService.swift
var isConfigured: Bool {
    // Vérifie si :
    // 1. Le Client ID existe
    // 2. Le Client Secret existe dans Keychain
    // 3. Le Tenant ID existe
    return !clientId.isEmpty && !clientSecret.isEmpty && !tenantId.isEmpty
}
```

---

## 🎯 Solution

### Étape 1 : Configurer Azure AD

**Dans l'application iPad, aller dans :**

```
Réglages (⚙️) → SharePoint / Azure AD
```

**Remplir les informations :**

| Champ | Valeur | Où trouver ? |
|-------|--------|--------------|
| **Client ID** | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | Azure Portal → App Registrations |
| **Client Secret** | `xxxxxxxxxxxxxxxxxxxxxxxxxxxxx` | Azure Portal → Certificates & secrets |
| **Tenant ID** | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` | Azure Portal → Overview |
| **Site URL** | `sncf.sharepoint.com:/sites/railskillsgrpo365` | Configuré par défaut ✅ |

---

### Étape 2 : Vérifier la configuration

**Tester la connexion SharePoint :**

```
Réglages → SharePoint → Bouton "Tester la connexion"
```

**Résultat attendu :**
```
✅ Connexion réussie
✅ Site SharePoint trouvé
✅ Accès au dossier RailSkills validé
```

---

### Étape 3 : Synchroniser manuellement (première fois)

**Aller dans :**

```
Réglages → SharePoint → Bouton "Synchroniser maintenant"
```

**Cela va créer :**

```
SharePoint/RailSkills/
└── CTT_sylvain.gallon/           # Dossier du CTT connecté
    ├── Data/                      # Dossiers des conducteurs
    │   ├── Jean_Dupont/
    │   │   ├── Jean_Dupont.json
    │   │   └── Jean_Dupont_backup.json
    │   ├── Marie_Martin/
    │   │   ├── Marie_Martin.json
    │   │   └── Marie_Martin_backup.json
    │   └── ...
    └── Checklists/                # Checklists
        ├── Triennale_CFL.json
        └── Triennale_CFL_backup.json
```

---

## 🔐 Comment obtenir les identifiants Azure AD ?

### Option 1 : Vous avez déjà une App Registration Azure

**1. Se connecter au portail Azure**
```
https://portal.azure.com
```

**2. Aller dans "App registrations"**
```
Azure Active Directory → App registrations → RailSkills
```

**3. Récupérer les informations**

| Information | Emplacement dans Azure |
|------------|------------------------|
| **Client ID** | Overview → Application (client) ID |
| **Tenant ID** | Overview → Directory (tenant) ID |
| **Client Secret** | Certificates & secrets → Client secrets → New client secret |

---

### Option 2 : Créer une nouvelle App Registration

**1. Dans le portail Azure :**
```
Azure Active Directory → App registrations → New registration
```

**2. Remplir :**
- **Name:** RailSkills
- **Supported account types:** Single tenant
- **Redirect URI:** (laisser vide pour l'instant)

**3. Après création :**
- Copier le **Application (client) ID**
- Copier le **Directory (tenant) ID**

**4. Créer un Client Secret :**
```
Certificates & secrets → New client secret
→ Description: "RailSkills Secret Organisationnel"
→ Expires: 24 months (recommandé)
→ Add
→ ⚠️ COPIER LA VALEUR IMMÉDIATEMENT (ne sera plus visible après)
```

**5. Configurer les permissions Microsoft Graph :**
```
API permissions → Add a permission → Microsoft Graph → Application permissions
→ Ajouter :
   - Sites.ReadWrite.All
   - Files.ReadWrite.All
→ Grant admin consent (demander à l'administrateur Azure de valider)
```

---

## 🚀 Synchronisation automatique après configuration

Une fois Azure AD configuré, la synchronisation devient **automatique** :

### Déclenchement automatique

✅ **Ajout d'un conducteur** → Sync auto vers SharePoint (après 2 secondes)  
✅ **Modification d'un état** → Sync auto vers SharePoint  
✅ **Ajout d'une note** → Sync auto vers SharePoint  
✅ **Import d'une checklist** → Sync auto vers SharePoint  

### Débouncing intelligent

```swift
// Store.swift (lignes 559-565)
// La synchronisation attend 2 secondes après la dernière modification
// pour éviter de surcharger SharePoint
.delay(for: .seconds(AppConstants.Debounce.sharePointSyncDelay), scheduler: RunLoop.main)
```

**Avantages :**
- Pas de surcharge réseau
- Batch des modifications rapprochées
- Synchronisation en arrière-plan (non bloquante)

---

## 🧪 Test de diagnostic

### Vérifier si Azure AD est configuré

**Dans Xcode Console, après connexion :**

```bash
# Filtrer les logs par catégorie "SharePointSync"
# Si vous voyez :
❌ "Service SharePoint non configuré"
→ Azure AD manquant

✅ "Conducteur 'Jean Dupont' synchronisé vers SharePoint"
→ Tout fonctionne !
```

### Logs à surveiller

```
[SharePointSync] Récupération de l'ID du site SharePoint
[SharePointSync] ID du site SharePoint récupéré: xxx
[SharePointSync] Dossier créé: RailSkills/CTT_sylvain.gallon
[SharePointSync] Dossier créé: RailSkills/CTT_sylvain.gallon/Data
[SharePointSync] Synchronisation du conducteur 'Jean Dupont' dans le dossier 'Jean_Dupont'
[SharePointSync] Fichier téléversé: RailSkills/CTT_sylvain.gallon/Data/Jean_Dupont/Jean_Dupont.json
[SharePointSync] ✅ Conducteur 'Jean Dupont' synchronisé vers SharePoint
```

---

## 📋 Checklist de résolution

- [ ] Se connecter à l'app avec email/password
- [ ] Aller dans Réglages → SharePoint / Azure AD
- [ ] Entrer Client ID, Client Secret, Tenant ID
- [ ] Tester la connexion SharePoint
- [ ] Activer "Synchronisation automatique"
- [ ] Cliquer sur "Synchroniser maintenant"
- [ ] Vérifier dans SharePoint que les dossiers sont créés :
  - `RailSkills/CTT_{votre_cttId}/Data/`
  - `RailSkills/CTT_{votre_cttId}/Checklists/`
- [ ] Ajouter un nouveau conducteur dans l'app
- [ ] Attendre 2 secondes
- [ ] Vérifier que le dossier du conducteur est créé sur SharePoint

---

## ⚠️ Si le problème persiste

### Vérifier les permissions Azure

**Dans le portail Azure :**
```
App registrations → RailSkills → API permissions
```

**Permissions requises :**
- ✅ `Sites.ReadWrite.All` (Application)
- ✅ `Files.ReadWrite.All` (Application)
- ✅ **Admin consent granted** (validé par l'admin)

### Vérifier l'URL du site SharePoint

**Dans SharePointSyncService.swift (ligne 16) :**
```swift
private let sitePath = "sncf.sharepoint.com:/sites/railskillsgrpo365"
```

**Vérifier que cette URL correspond à votre site SharePoint.**

**Pour trouver l'URL correcte :**
1. Ouvrir votre site SharePoint dans un navigateur
2. L'URL ressemble à : `https://sncf.sharepoint.com/sites/railskillsgrpo365`
3. Utiliser : `sncf.sharepoint.com:/sites/railskillsgrpo365` (sans `https://`)

### Vérifier le CTT ID

**Dans Xcode Console, filtrer "SharePointSync" :**
```
[SharePointSync] CTT connecté : sylvain.gallon
[SharePointSync] Dossier SharePoint : CTT_sylvain.gallon
```

**Si vous voyez :**
```
[SharePointSync] ⚠️ Aucun utilisateur connecté, utilisation du dossier 'Dev'
```
→ **Problème** : L'utilisateur n'est pas connecté correctement  
→ **Solution** : Se reconnecter avec email/password

---

## 🆘 Contact support

Si après toutes ces étapes les dossiers ne sont toujours pas créés, fournir les informations suivantes :

1. **Capture d'écran de la page Réglages → SharePoint**
2. **Logs Xcode filtrés par "SharePointSync"**
3. **Capture d'écran du portail Azure → App Registration → Permissions**
4. **Confirmation que le site SharePoint `sncf.sharepoint.com/sites/railskillsgrpo365` existe et est accessible**

---

**Auteur :** Assistant IA  
**Dernière mise à jour :** 26 novembre 2025


