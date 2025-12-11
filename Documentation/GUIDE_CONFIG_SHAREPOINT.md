# 🚀 Guide de configuration SharePoint - 5 minutes

**Pourquoi les dossiers ne sont pas créés ?**  
→ SharePoint n'est pas encore configuré dans l'application.

---

## 📱 Étapes dans l'application iPad

### 1️⃣ Ouvrir les Réglages

```
App RailSkills → ⚙️ (en haut à droite) → Réglages
```

### 2️⃣ Trouver la section "Synchronisation"

Vous verrez :

```
📁 Synchronisation

☁️ Synchronisation SharePoint
   Non configuré - Configurer Azure AD
   [Toucher pour configurer >]
```

### 3️⃣ Toucher "Synchronisation SharePoint"

Cela ouvre la page de configuration Azure AD.

---

## 🔐 Informations nécessaires

Vous avez besoin de **3 informations** du portail Azure :

| Information | Exemple | Où la trouver ? |
|------------|---------|-----------------|
| **Client ID** | `12345678-1234-1234-1234-123456789abc` | Azure Portal → App Registration → Overview |
| **Client Secret** | `AbC123~XyZ789...` | Azure Portal → Certificates & secrets |
| **Tenant ID** | `87654321-4321-4321-4321-cba987654321` | Azure Portal → App Registration → Overview |

---

## 🌐 Obtenir les identifiants Azure (si nécessaire)

### Option A : Vous avez déjà une App Registration "RailSkills"

1. Ouvrir https://portal.azure.com
2. **Azure Active Directory** → **App registrations** → **RailSkills**
3. **Copier :**
   - **Application (client) ID** → C'est le `Client ID`
   - **Directory (tenant) ID** → C'est le `Tenant ID`
4. **Aller dans** : **Certificates & secrets** → **New client secret**
   - Description : "RailSkills Secret"
   - Expiration : 24 mois
   - **Add**
   - ⚠️ **COPIER LA VALEUR IMMÉDIATEMENT** (ne sera plus visible)

### Option B : Créer une nouvelle App Registration

**1. Dans le portail Azure :**
```
Azure Active Directory → App registrations → New registration
```

**2. Remplir :**
- **Name:** `RailSkills`
- **Supported account types:** `Accounts in this organizational directory only`
- **Redirect URI:** (laisser vide)
- Cliquer sur **Register**

**3. Après la création :**
- **Copier** : `Application (client) ID` → C'est le `Client ID`
- **Copier** : `Directory (tenant) ID` → C'est le `Tenant ID`

**4. Créer un Client Secret :**
```
Certificates & secrets → New client secret
→ Description: "RailSkills Secret"
→ Expires: 24 months
→ Add
→ ⚠️ COPIER LA VALEUR (ne sera plus visible après)
```

**5. Configurer les permissions :**
```
API permissions → Add a permission → Microsoft Graph → Application permissions
→ Cocher :
   ☑️ Sites.ReadWrite.All
   ☑️ Files.ReadWrite.All
→ Add permissions
→ Grant admin consent (cliquer sur le bouton "Grant admin consent for...")
```

---

## ✅ Configurer dans l'iPad

### Étape 1 : Entrer les identifiants

Dans la page "Configuration Azure AD" de l'app :

```
Client ID     : [Coller le Client ID]
Client Secret : [Coller le Client Secret]
Tenant ID     : [Coller le Tenant ID]
Site URL      : sncf.sharepoint.com:/sites/railskillsgrpo365
                ✅ (déjà rempli par défaut)
```

### Étape 2 : Enregistrer

Toucher le bouton **"Enregistrer"**

### Étape 3 : Tester la connexion (optionnel mais recommandé)

Toucher le bouton **"Tester la connexion"**

**Résultat attendu :**
```
✅ Connexion réussie
✅ Site SharePoint trouvé
✅ Accès validé
```

### Étape 4 : Activer la synchronisation automatique

Retour dans **Réglages** → **Synchronisation**

Vous verrez maintenant :

```
☁️ Synchronisation SharePoint automatique
   ○ (toggle désactivé)
```

**Activer le toggle** → Il devient :

```
☁️ Synchronisation SharePoint automatique
   ● (toggle activé en bleu)
```

---

## 🎉 C'est fait !

### Vérification immédiate

**1. Aller dans la vue des conducteurs**
```
App RailSkills → Conducteurs
```

**2. Modifier un conducteur existant OU en créer un nouveau**

**3. Attendre 2 secondes**

**4. Vérifier dans SharePoint**

Ouvrir votre SharePoint dans un navigateur :
```
https://sncf.sharepoint.com/sites/railskillsgrpo365
```

**Naviguer vers :**
```
Documents → RailSkills → CTT_sylvain.gallon → Data
```

**Vous devez voir :**
```
📁 Data/
  ├── 📁 Jean_Dupont/
  │   ├── Jean_Dupont.json
  │   └── Jean_Dupont_backup.json
  ├── 📁 Marie_Martin/
  │   ├── Marie_Martin.json
  │   └── Marie_Martin_backup.json
  └── ...
```

---

## 🔄 Synchronisation future

### Automatique (recommandé)

Une fois configuré, **tout est automatique** :

✅ Vous ajoutez un conducteur → Sync après 2 secondes  
✅ Vous modifiez un état → Sync après 2 secondes  
✅ Vous ajoutez une note → Sync après 2 secondes  
✅ Vous importez une checklist → Sync immédiate  

### Manuelle (optionnel)

Vous pouvez aussi synchroniser manuellement :

```
Réglages → Synchronisation → Synchronisation manuelle SharePoint
```

**Avantages :**
- Voir l'historique des synchronisations
- Forcer une synchronisation immédiate
- Voir les statistiques (fichiers envoyés, etc.)

---

## ⚠️ Points d'attention

### Le site SharePoint doit exister

Vérifier que `https://sncf.sharepoint.com/sites/railskillsgrpo365` est accessible :

- Ouvrir l'URL dans un navigateur
- Se connecter avec votre compte SNCF
- Vérifier que le site s'affiche

**Si le site n'existe pas :**
- Le créer dans SharePoint Admin Center
- OU modifier l'URL dans le code (`Services/SharePointSyncService.swift`, ligne 16)

### Les permissions Azure doivent être accordées

Dans le portail Azure :
```
App registrations → RailSkills → API permissions
```

**Vérifier que :**
- ✅ `Sites.ReadWrite.All` est présent
- ✅ `Files.ReadWrite.All` est présent
- ✅ **Admin consent granted** (cadenas vert) est visible

**Si "Admin consent not granted" :**
- Cliquer sur **"Grant admin consent for [votre organisation]"**
- Se connecter en tant qu'administrateur Azure
- Accepter les permissions

---

## 🆘 Dépannage

### Erreur "Site SharePoint introuvable"

**Cause :** L'URL du site est incorrecte

**Solution :**
1. Ouvrir votre site SharePoint dans un navigateur
2. Copier l'URL (ex: `https://sncf.sharepoint.com/sites/mon-site`)
3. Dans l'app iPad, modifier l'URL vers :
   ```
   sncf.sharepoint.com:/sites/mon-site
   ```

### Erreur "Accès refusé"

**Cause :** Les permissions Azure ne sont pas accordées

**Solution :**
1. Portail Azure → App registrations → RailSkills
2. API permissions
3. Grant admin consent
4. Retester dans l'app

### "Synchronisation automatique ne fonctionne pas"

**Vérifier :**
1. **Toggle activé ?** → Réglages → Synchronisation SharePoint automatique
2. **Azure AD configuré ?** → Réglages → Voir "Azure AD configuré ✅"
3. **Connexion Internet ?** → Wi-Fi ou 4G activé
4. **Logs dans Xcode** :
   ```
   Filtrer par "SharePointSync"
   Vérifier les messages d'erreur
   ```

---

## 📊 Récapitulatif

| Étape | Temps | Statut |
|-------|-------|--------|
| 1. Obtenir identifiants Azure | 5 min | ⏳ |
| 2. Configurer dans l'app | 1 min | ⏳ |
| 3. Tester la connexion | 30 sec | ⏳ |
| 4. Activer sync auto | 10 sec | ⏳ |
| 5. Vérifier dans SharePoint | 1 min | ⏳ |

**Total : ~8 minutes** ⏱️

---

## ✨ Bénéfices après configuration

### Pour vous (CTT)

✅ **Sauvegarde centralisée** : Tous vos conducteurs sont archivés automatiquement  
✅ **Accessibilité** : Consultez les données depuis n'importe quel navigateur  
✅ **Collaboration** : Partagez les données avec d'autres CTT  
✅ **Historique** : Fichiers backup pour récupération en cas de problème  

### Pour l'organisation

✅ **Conformité** : Traçabilité complète des évaluations  
✅ **Audit** : Accès centralisé pour les vérifications réglementaires  
✅ **Reporting** : Données structurées pour analyses statistiques  
✅ **Sécurité** : Données stockées sur infrastructure Microsoft  

---

**Besoin d'aide ?**  
Consultez `DIAGNOSTIC_SHAREPOINT.md` pour un diagnostic approfondi.

**Auteur :** Assistant IA  
**Dernière mise à jour :** 26 novembre 2025


