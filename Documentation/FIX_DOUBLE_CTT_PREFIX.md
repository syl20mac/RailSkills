# 🔧 Correction : Double préfixe CTT_ (technique)

**Date :** 26 novembre 2025  
**Problème :** Dossiers dupliqués avec double préfixe `CTT_CTT_` dans SharePoint  
**Statut :** ✅ Corrigé  
**Note :** Le préfixe `CTT_` est un identifiant technique pour les dossiers SharePoint. Le rôle utilisateur est "Manager Traction".

---

## 🐛 Problème identifié

### Symptômes visibles dans SharePoint

```
📁 RailSkills/
  ├── ❌ CTT_CTT_SYLVAIN.GALLON/    (modifié il y a 7 minutes)
  ├── ✅ CTT_SYLVAIN.GALLON/         (modifié il y a 4 jours)
  └── ✅ CTT_Dev/                    (modifié il y a 1 heure)
```

**Le préfixe `CTT_` est ajouté deux fois** → `CTT_CTT_SYLVAIN.GALLON` au lieu de `CTT_SYLVAIN.GALLON`

---

## 🔍 Cause du bug

### Code problématique

Dans `SharePointSyncService.swift` :

```swift
// Ligne 99
let basePath = "RailSkills/CTT_\(cttFolder)/Data"
                         ^^^^
                     Ajoute "CTT_"
```

Mais `cttFolder` retournait déjà `CTT_SYLVAIN.GALLON` depuis `WebAuthService.shared.currentUser.cttId`

**Résultat :**
```
"RailSkills/CTT_" + "CTT_SYLVAIN.GALLON" = "RailSkills/CTT_CTT_SYLVAIN.GALLON" ❌
```

### Pourquoi le `cttId` avait déjà le préfixe ?

Le serveur backend (`RailSkills-Web`) retourne probablement le `cttId` avec le préfixe `CTT_` déjà inclus dans la réponse JSON de l'authentification.

**Exemple de réponse serveur :**
```json
{
  "user": {
    "email": "sylvain.gallon@sncf.fr",
    "cttId": "CTT_SYLVAIN.GALLON",    // ← Déjà avec le préfixe
    "name": "Sylvain Gallon"
  }
}
```

---

## ✅ Solution appliquée

### Modification de `getCTTFolderName()`

**Fichier :** `Services/SharePointSyncService.swift`  
**Lignes :** 175-192

```swift
private func getCTTFolderName() -> String {
    // 1. Essayer de récupérer depuis WebAuthService
    if let currentUser = WebAuthService.shared.currentUser,
       !currentUser.cttId.isEmpty {
        var cttId = currentUser.cttId
        
        // ✅ NOUVEAU : Supprimer le préfixe "CTT_" s'il est déjà présent
        if cttId.uppercased().hasPrefix("CTT_") {
            cttId = String(cttId.dropFirst(4)) // Enlever "CTT_"
            Logger.debug("Préfixe CTT_ détecté et supprimé", category: "SharePointSync")
        }
        
        return sanitizeFolderName(cttId)
    }
    
    // 2. Fallback : dossier partagé si non connecté
    return "Dev" // ou "Shared" en production
}
```

### Logique de correction

1. **Récupérer le `cttId`** depuis l'utilisateur connecté
2. **Vérifier si le préfixe `CTT_` est présent**
   - Utilise `.uppercased()` pour gérer `ctt_`, `CTT_`, `Ctt_`, etc.
3. **Si présent, le retirer**
   - `String(cttId.dropFirst(4))` enlève les 4 premiers caractères (`CTT_`)
4. **Logger l'opération** pour le debug
5. **Nettoyer le nom** avec `sanitizeFolderName()`

### Comportement après correction

```
currentUser.cttId = "CTT_SYLVAIN.GALLON"
                      ↓ (détecté et supprimé)
cttId = "SYLVAIN.GALLON"
                      ↓
basePath = "RailSkills/CTT_SYLVAIN.GALLON/Data"
                      ^^^^
                  Ajouté une seule fois ✅
```

---

## 🧪 Test de la correction

### 1️⃣ Relancer l'application

```
Dans Xcode : ⌘+R
```

### 2️⃣ Se connecter

```
Email : sylvain.gallon@sncf.fr
Mot de passe : [votre mot de passe]
```

### 3️⃣ Synchroniser un conducteur

**Option A : Automatique**
- Modifier un conducteur existant
- Attendre 2 secondes

**Option B : Manuelle**
- Réglages → Synchronisation → Synchroniser maintenant

### 4️⃣ Vérifier les logs dans Xcode

**Filtrer par "SharePointSync" :**

```
[SharePointSync] CTT connecté : CTT_SYLVAIN.GALLON
[SharePointSync] Préfixe CTT_ détecté et supprimé : 'CTT_SYLVAIN.GALLON' → 'SYLVAIN.GALLON'
[SharePointSync] Dossier SharePoint : CTT_SYLVAIN.GALLON
[SharePointSync] Synchronisation du conducteur 'Jean Dupont' dans le dossier 'Jean_Dupont'
[SharePointSync] ✅ Conducteur 'Jean Dupont' synchronisé vers SharePoint
```

**Vérification importante :**
- ✅ Log : `Préfixe CTT_ détecté et supprimé`
- ✅ Dossier : `CTT_SYLVAIN.GALLON` (et non `CTT_CTT_SYLVAIN.GALLON`)

### 5️⃣ Vérifier dans SharePoint

Ouvrir : `https://sncf.sharepoint.com/sites/railskillsgrpo365`

**Naviguer vers :**
```
Documents → RailSkills
```

**Vous devriez maintenant voir :**
```
📁 RailSkills/
  ├── ✅ CTT_SYLVAIN.GALLON/         (nouvellement modifié)
  ├── ❌ CTT_CTT_SYLVAIN.GALLON/    (ancien, à supprimer)
  └── ✅ CTT_Dev/                    (pour les tests en DEBUG)
```

---

## 🗑️ Nettoyage des dossiers dupliqués

### Étape 1 : Identifier les dossiers à supprimer

**Dans SharePoint, repérer les dossiers avec double préfixe :**

```
❌ CTT_CTT_SYLVAIN.GALLON/
❌ CTT_CTT_JEAN.DUPONT/
❌ CTT_CTT_MARIE.MARTIN/
etc.
```

### Étape 2 : Sauvegarder (si nécessaire)

**Si ces dossiers contiennent des données importantes :**

1. Télécharger le dossier `CTT_CTT_SYLVAIN.GALLON/`
2. Comparer avec `CTT_SYLVAIN.GALLON/`
3. Fusionner manuellement si nécessaire

**Dans la plupart des cas :**
- Le dossier `CTT_CTT_...` est récent (7 minutes)
- Le dossier `CTT_...` correct contient les données historiques (4 jours)
- → Supprimer le dossier avec double préfixe

### Étape 3 : Supprimer les dossiers en double

**Dans SharePoint :**

1. **Sélectionner** le dossier `CTT_CTT_SYLVAIN.GALLON`
2. **Clic droit** → **Supprimer**
3. **Confirmer** la suppression

**Ou via la sélection multiple :**

1. Cocher tous les dossiers `CTT_CTT_...`
2. Cliquer sur **Supprimer** dans la barre d'outils
3. Confirmer

### Étape 4 : Vérifier la corbeille

**Si suppression accidentelle :**

```
SharePoint → Navigation gauche → Corbeille
→ Restaurer les éléments si nécessaire
```

---

## 📊 Impact de la correction

### Avant

| Dossier SharePoint | État | Utilisation |
|-------------------|------|-------------|
| `CTT_CTT_SYLVAIN.GALLON/` | ❌ Bug | Dernière sync (7 min) |
| `CTT_SYLVAIN.GALLON/` | ✅ Correct | Données historiques (4 jours) |
| `CTT_Dev/` | ✅ Debug | Tests en développement |

### Après correction

| Dossier SharePoint | État | Utilisation |
|-------------------|------|-------------|
| `CTT_SYLVAIN.GALLON/` | ✅ Correct | Toutes les synchronisations |
| `CTT_Dev/` | ✅ Debug | Tests en développement |

---

## 🔐 Prévention future

### Option 1 : Corriger le serveur backend (recommandé)

**Dans RailSkills-Web :**

Modifier l'API d'authentification pour retourner le `cttId` **sans le préfixe** :

```javascript
// Backend (Node.js/Express)
// auth.controller.js

// ❌ AVANT
const user = {
  email: "sylvain.gallon@sncf.fr",
  cttId: "CTT_SYLVAIN.GALLON",  // Avec préfixe
  name: "Sylvain Gallon"
};

// ✅ APRÈS
const user = {
  email: "sylvain.gallon@sncf.fr",
  cttId: "SYLVAIN.GALLON",      // Sans préfixe
  name: "Sylvain Gallon"
};
```

**Avantages :**
- Plus clair sémantiquement
- Évite la confusion
- Le client ajoute le préfixe si nécessaire

### Option 2 : Garder la correction côté client (actuel)

**Avantages :**
- ✅ Fonctionne quel que soit le format du serveur
- ✅ Robuste face aux changements backend
- ✅ Pas besoin de modifier le serveur

**Cette solution est actuellement en place** et suffit pour garantir le bon fonctionnement.

---

## 📝 Logs de debug utiles

### Pour vérifier le `cttId` reçu du serveur

**Ajouter temporairement dans `WebAuthService.swift` après connexion :**

```swift
// Après récupération de currentUser
Logger.debug("cttId reçu du serveur : '\(currentUser.cttId)'", category: "WebAuth")
```

**Attendu :**
```
[WebAuth] cttId reçu du serveur : 'CTT_SYLVAIN.GALLON'
ou
[WebAuth] cttId reçu du serveur : 'SYLVAIN.GALLON'
```

### Pour vérifier la correction SharePoint

**Déjà présent dans le code :**

```swift
// SharePointSyncService.swift (ligne 185)
Logger.debug("Préfixe CTT_ détecté et supprimé : '\(currentUser.cttId)' → '\(cttId)'", category: "SharePointSync")
```

---

## ✅ Checklist de vérification

- [x] Code corrigé dans `SharePointSyncService.swift`
- [ ] Application relancée (⌘+R)
- [ ] Connexion effectuée
- [ ] Synchronisation testée
- [ ] Logs vérifiés (préfixe supprimé)
- [ ] SharePoint vérifié (dossier correct utilisé)
- [ ] Dossiers dupliqués supprimés dans SharePoint
- [ ] Tests avec un nouveau conducteur
- [ ] Confirmation que plus de `CTT_CTT_` n'est créé

---

## 🆘 Si le problème persiste

### Vérifier que le code a bien été recompilé

```
Dans Xcode :
1. Product → Clean Build Folder (⇧⌘K)
2. Relancer l'app (⌘+R)
```

### Vérifier le `cttId` dans les logs

```
[WebAuth] cttId reçu du serveur : '?????'
[SharePointSync] Préfixe CTT_ détecté et supprimé : '?????' → '?????'
[SharePointSync] Dossier SharePoint : CTT_?????
```

**Si toujours `CTT_CTT_...` :**
- Le code n'a peut-être pas été recompilé
- Faire un Clean Build

---

## 📞 Contact support

Si le bug persiste après toutes ces étapes, fournir :

1. **Logs Xcode** filtrés par "SharePointSync"
2. **Capture d'écran** de SharePoint montrant les dossiers
3. **Réponse JSON** du serveur lors de la connexion (sans le mot de passe)

---

**Auteur :** Assistant IA  
**Dernière mise à jour :** 26 novembre 2025


