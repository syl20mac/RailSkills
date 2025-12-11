# 🎯 Prompt pour RailSkills-Web : Segmentation SharePoint et Archives

## 📋 Contexte

RailSkills est composé de **2 applications** :
1. **RailSkills (iOS)** - Application iPad/iPhone pour les CTT sur le terrain ✅ CORRIGÉ
2. **RailSkills-Web** - Application web/NAS pour le traitement des données ⚠️ À CORRIGER

Les mêmes corrections doivent être appliquées sur **RailSkills-Web** pour assurer la cohérence.

---

## 🎯 Objectifs des corrections

### 1. Segmentation par CTT
**Problème** : Tous les conducteurs et checklists sont dans un dossier global SharePoint  
**Solution** : Organiser par dossier CTT basé sur le `cttId` de l'utilisateur connecté

### 2. Archives uniques
**Problème** : Accumulation infinie de fichiers avec timestamp à chaque synchronisation  
**Solution** : 1 fichier principal + 1 backup (écrasé à chaque fois)

---

## 📁 Structure SharePoint actuelle (AVANT)

```
SharePoint/RailSkills/
└── Data/
    ├── Conducteur_A/
    │   ├── Conducteur_A_1732460123.json
    │   ├── Conducteur_A_1732460456.json
    │   └── Conducteur_A_1732460789.json
    └── Conducteur_B/
        ├── Conducteur_B_1732460123.json
        └── ...
```

**Problèmes** :
- ❌ Tous les CTT au même niveau (pas de séparation)
- ❌ Archives infinies (accumulation de fichiers)
- ❌ Impossible de savoir quel conducteur appartient à quel CTT

---

## 📁 Structure SharePoint cible (APRÈS)

```
SharePoint/RailSkills/
├── CTT_jean.dupont/
│   ├── Data/
│   │   ├── Conducteur_A/
│   │   │   ├── Conducteur_A.json         # Version actuelle
│   │   │   └── Conducteur_A_backup.json  # Version de backup
│   │   └── Conducteur_B/
│   │       ├── Conducteur_B.json
│   │       └── Conducteur_B_backup.json
│   └── Checklists/
│       ├── Checklist_CFL.json
│       └── Checklist_CFL_backup.json
│
└── CTT_marie.martin/
    ├── Data/
    │   └── Conducteur_C/
    │       ├── Conducteur_C.json
    │       └── Conducteur_C_backup.json
    └── Checklists/
        ├── Checklist_CFL.json
        └── Checklist_CFL_backup.json
```

**Avantages** :
- ✅ Séparation claire par CTT
- ✅ 2 fichiers max par élément (principal + backup)
- ✅ Structure organisée et prévisible
- ✅ 99% de fichiers en moins

---

## 🔧 Modifications à appliquer

### Modification 1 : Ajouter une fonction `getCTTFolderName()`

**Dans le service SharePoint de RailSkills-Web** :

```typescript
// ou JavaScript selon votre stack

/**
 * Récupère le nom du dossier CTT depuis l'utilisateur connecté
 * @returns Le nom du dossier CTT (ex: "jean.dupont" ou "Shared")
 */
function getCTTFolderName(currentUser) {
    // 1. Essayer de récupérer depuis l'utilisateur connecté
    if (currentUser && currentUser.cttId && currentUser.cttId.trim() !== '') {
        return sanitizeFolderName(currentUser.cttId);
    }
    
    // 2. Fallback : dossier partagé si non connecté
    if (process.env.NODE_ENV === 'development') {
        console.warn('Aucun utilisateur connecté, utilisation du dossier "Dev" pour SharePoint');
        return 'Dev';
    } else {
        console.warn('Aucun utilisateur connecté, utilisation du dossier "Shared" pour SharePoint');
        return 'Shared';
    }
}

/**
 * Nettoie un nom pour être utilisé comme nom de dossier SharePoint
 */
function sanitizeFolderName(name) {
    let sanitized = name
        .replace(/\s+/g, '_')           // Espaces → underscores
        .replace(/[\/\\]/g, '-')        // Slashes → tirets
        .replace(/__+/g, '_')           // Underscores multiples → simple
        .replace(/^_+|_+$/g, '');       // Supprimer underscores début/fin
    
    // Limiter la longueur (max 200 caractères pour SharePoint)
    if (sanitized.length > 200) {
        sanitized = sanitized.substring(0, 200);
    }
    
    return sanitized;
}
```

---

### Modification 2 : Synchronisation des conducteurs

**Chercher la fonction qui synchronise les conducteurs vers SharePoint.**

#### Avant (à remplacer)
```javascript
// Structure globale
const basePath = 'RailSkills/Data';

// Archive avec timestamp
const timestamp = Date.now();
const archiveFileName = `${driverName}_${timestamp}.json`;
await uploadFile(siteId, archiveFileName, data, driverFolderPath, false);
```

#### Après (nouveau code)
```javascript
// Structure par CTT
const cttFolder = getCTTFolderName(currentUser);
const basePath = `RailSkills/CTT_${cttFolder}/Data`;

// Créer le dossier CTT s'il n'existe pas
await ensureFolderExists(siteId, basePath);

// Pour chaque conducteur
for (const driver of drivers) {
    const sanitizedName = sanitizeFolderName(driver.name);
    const folderName = sanitizedName || driver.id;
    const driverFolderPath = `${basePath}/${folderName}`;
    
    await ensureFolderExists(siteId, driverFolderPath);
    
    // 1. Fichier principal (écrasé à chaque sync)
    const fileName = `${folderName}.json`;
    await uploadFile(siteId, fileName, driverData, driverFolderPath, true);
    
    // 2. Backup unique (écrasé à chaque sync)
    const backupFileName = `${folderName}_backup.json`;
    await uploadFile(siteId, backupFileName, driverData, driverFolderPath, true);
}
```

**Points clés** :
- `overwrite: true` pour ÉCRASER les fichiers existants
- Nom fixe pour le backup : `_backup.json` (pas de timestamp)
- Utilisation du `cttFolder` dans le chemin

---

### Modification 3 : Synchronisation des checklists

**Chercher la fonction qui synchronise les checklists vers SharePoint.**

#### Avant (à remplacer)
```javascript
const checklistsPath = 'RailSkills/Checklists';
const fileName = `${checklist.title}_${Date.now()}.json`;
await uploadFile(siteId, fileName, data, checklistsPath, false);
```

#### Après (nouveau code)
```javascript
// Structure par CTT
const cttFolder = getCTTFolderName(currentUser);
const checklistsPath = `RailSkills/CTT_${cttFolder}/Checklists`;

await ensureFolderExists(siteId, checklistsPath);

const cleanTitle = checklist.title.replace(/\s+/g, '_');

// 1. Fichier principal (écrasé à chaque sync)
const fileName = `${cleanTitle}.json`;
await uploadFile(siteId, fileName, checklistData, checklistsPath, true);

// 2. Backup unique (écrasé à chaque sync)
const backupFileName = `${cleanTitle}_backup.json`;
await uploadFile(siteId, backupFileName, checklistData, checklistsPath, true);
```

---

### Modification 4 : Lecture des conducteurs depuis SharePoint

**Chercher la fonction qui lit les conducteurs depuis SharePoint.**

#### Avant
```javascript
const basePath = 'RailSkills/Data';
const drivers = await fetchDriversFromPath(siteId, basePath);
```

#### Après
```javascript
// Lire depuis la structure par CTT
const cttFolder = getCTTFolderName(currentUser);
const basePath = `RailSkills/CTT_${cttFolder}/Data`;
const drivers = await fetchDriversFromPath(siteId, basePath);
```

---

## 📊 Résumé des changements

| Élément | Avant | Après |
|---------|-------|-------|
| **Chemin conducteurs** | `RailSkills/Data/` | `RailSkills/CTT_{cttId}/Data/` |
| **Chemin checklists** | `RailSkills/Checklists/` | `RailSkills/CTT_{cttId}/Checklists/` |
| **Nom fichier principal** | Inchangé | Inchangé |
| **Nom archive** | `{nom}_{timestamp}.json` | `{nom}_backup.json` |
| **Overwrite archive** | `false` (accumulation) | `true` (1 seul fichier) |
| **Nombre de fichiers** | Infini (accumulation) | 2 par élément |

---

## 🎯 Impact attendu

### Pour 1 CTT avec 20 conducteurs et 1 checklist

#### Avant
- Conducteurs : 20 × 10 sync/jour × 30 jours = **6 000 fichiers**
- Checklists : 1 × 5 modif/jour × 30 jours = **150 fichiers**
- **TOTAL : ~6 150 fichiers**

#### Après
- Conducteurs : 20 × 2 fichiers = **40 fichiers**
- Checklists : 1 × 2 fichiers = **2 fichiers**
- **TOTAL : 42 fichiers**

**Réduction : 99.3% de fichiers en moins !**

---

## 🧪 Tests à effectuer

### Test 1 : Connexion et structure CTT
```javascript
// 1. Utilisateur se connecte
const user = await login('jean.dupont@sncf.fr', 'password');

// 2. Ajouter un conducteur
const driver = { name: 'Test Conducteur' };
await syncDriver(driver, user);

// 3. Vérifier sur SharePoint
// Doit créer : RailSkills/CTT_jean.dupont/Data/Test_Conducteur/
```

### Test 2 : Archives uniques
```javascript
// 1. Synchroniser un conducteur
await syncDriver(driver1, user);

// 2. Modifier et re-synchroniser 5 fois
for (let i = 0; i < 5; i++) {
    driver1.notes = `Note ${i}`;
    await syncDriver(driver1, user);
}

// 3. Vérifier qu'il y a SEULEMENT 2 fichiers :
// - Test_Conducteur.json
// - Test_Conducteur_backup.json
```

### Test 3 : Multi-CTT
```javascript
// 1. CTT A ajoute conducteur
const userA = await login('jean.dupont@sncf.fr', 'pass');
await syncDriver({ name: 'Conducteur A' }, userA);

// 2. CTT B ajoute conducteur
const userB = await login('marie.martin@sncf.fr', 'pass');
await syncDriver({ name: 'Conducteur B' }, userB);

// 3. Vérifier la séparation :
// - CTT_jean.dupont/Data/Conducteur_A/
// - CTT_marie.martin/Data/Conducteur_B/
```

---

## 🔍 Fichiers à modifier (à chercher dans RailSkills-Web)

Chercher les fichiers contenant ces patterns :

### 1. Service SharePoint
```bash
# Chercher les fichiers qui gèrent SharePoint
grep -r "uploadFile\|SharePoint\|Graph API" --include="*.js" --include="*.ts"
```

Fichiers probables :
- `services/sharepoint.js` ou `services/sharepoint.ts`
- `services/sync.js` ou `services/sync.ts`
- `lib/sharepoint/`
- `utils/sharepoint.js`

### 2. Synchronisation des conducteurs
```bash
# Chercher la fonction de sync des conducteurs
grep -r "syncDrivers\|uploadDriver\|RailSkills/Data" --include="*.js" --include="*.ts"
```

### 3. Synchronisation des checklists
```bash
# Chercher la fonction de sync des checklists
grep -r "syncChecklist\|uploadChecklist\|RailSkills/Checklists" --include="*.js" --include="*.ts"
```

### 4. Authentification utilisateur
```bash
# Chercher où l'utilisateur connecté est stocké
grep -r "currentUser\|cttId\|userProfile" --include="*.js" --include="*.ts"
```

---

## 📝 Checklist de validation

Après avoir appliqué les modifications, vérifier :

### Code
- [ ] Fonction `getCTTFolderName()` créée
- [ ] Fonction `sanitizeFolderName()` créée
- [ ] Chemin conducteurs utilise `CTT_{cttId}/Data/`
- [ ] Chemin checklists utilise `CTT_{cttId}/Checklists/`
- [ ] Fichier principal : `{nom}.json`
- [ ] Fichier backup : `{nom}_backup.json`
- [ ] Paramètre `overwrite: true` pour les deux fichiers
- [ ] Suppression des timestamps dans les noms de fichiers

### Tests
- [ ] Connexion utilisateur fonctionne
- [ ] Structure CTT créée automatiquement
- [ ] 2 fichiers max par conducteur
- [ ] 2 fichiers max par checklist
- [ ] Backup écrasé à chaque sync
- [ ] Pas d'accumulation de fichiers
- [ ] Séparation entre différents CTT

### SharePoint
- [ ] Dossiers `CTT_{cttId}` créés
- [ ] Structure `Data/` et `Checklists/` présentes
- [ ] Anciens fichiers avec timestamp peuvent être supprimés
- [ ] 99% de réduction de fichiers confirmée

---

## 🧹 Script de nettoyage (optionnel)

Pour supprimer les anciennes archives avec timestamp :

```javascript
/**
 * Nettoie les anciennes archives avec timestamp
 * Garde seulement les fichiers principal et backup
 */
async function cleanupOldArchives(siteId, currentUser) {
    const cttFolder = getCTTFolderName(currentUser);
    const basePath = `RailSkills/CTT_${cttFolder}`;
    
    // 1. Nettoyer les conducteurs
    const driversPath = `${basePath}/Data`;
    const driverFolders = await listFolders(siteId, driversPath);
    
    for (const folderName of driverFolders) {
        const files = await listFiles(siteId, `${driversPath}/${folderName}`);
        
        for (const file of files) {
            const fileName = file.name;
            
            // Garder seulement principal et backup
            if (fileName !== `${folderName}.json` && 
                fileName !== `${folderName}_backup.json`) {
                await deleteFile(siteId, file.id);
                console.log(`Archive supprimée: ${fileName}`);
            }
        }
    }
    
    // 2. Nettoyer les checklists
    const checklistsPath = `${basePath}/Checklists`;
    const checklistFiles = await listFiles(siteId, checklistsPath);
    
    for (const file of checklistFiles) {
        const fileName = file.name;
        
        // Supprimer les fichiers avec timestamp (contient des chiffres longs)
        const hasTimestamp = /\d{13}/.test(fileName);
        if (hasTimestamp) {
            await deleteFile(siteId, file.id);
            console.log(`Archive checklist supprimée: ${fileName}`);
        }
    }
    
    console.log('Nettoyage terminé !');
}
```

---

## 📚 Référence : Ce qui a été fait sur iOS

### Fichier modifié
`Services/SharePointSyncService.swift`

### Fonctions ajoutées/modifiées
1. `getCTTFolderName()` - Récupère le dossier CTT
2. `syncDrivers()` - Modifiée pour structure CTT + backup unique
3. `syncChecklist()` - Modifiée pour structure CTT + backup unique
4. `fetchDrivers()` - Modifiée pour lire depuis structure CTT

### Commits importants
- Segmentation par CTT basée sur `cttId`
- Archives uniques avec `_backup.json`
- Suppression des timestamps dans les noms
- Overwrite activé pour éviter l'accumulation

---

## 🎯 Résumé pour l'IA

Voici ce que tu dois faire sur **RailSkills-Web** :

1. **Trouver** les fichiers qui gèrent la synchronisation SharePoint
2. **Ajouter** la fonction `getCTTFolderName()` qui récupère le `cttId` de l'utilisateur
3. **Modifier** les chemins de `RailSkills/Data/` vers `RailSkills/CTT_{cttId}/Data/`
4. **Modifier** les noms de fichiers de `{nom}_{timestamp}.json` vers `{nom}.json` et `{nom}_backup.json`
5. **Activer** l'overwrite (`true`) pour éviter l'accumulation
6. **Tester** que chaque CTT a son dossier et que les archives ne s'accumulent plus

**Objectif final** : Structure SharePoint identique à celle de l'app iOS.

---

**Date** : 24 novembre 2024  
**Pour** : RailSkills-Web (Node.js/NAS)  
**Basé sur** : Corrections RailSkills iOS v2.1  
**Priorité** : 🔴 Haute (cohérence entre les deux apps)



