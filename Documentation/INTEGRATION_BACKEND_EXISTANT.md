# 🔗 Intégration Backend Existant - Service Tokens SharePoint

**Projet :** RailSkills-Web/backend  
**Situation :** Backend Node.js déjà en fonctionnement  
**Objectif :** Ajouter le service de tokens SharePoint sans casser l'existant

---

## 🎯 Situation actuelle

D'après la capture d'écran, tu as déjà :

```
RailSkills-Web/
├── backend/
│   ├── src/
│   │   ├── .env                 ✅ Existe déjà
│   │   ├── server.js (ou index) ✅ Existe déjà
│   │   └── ...autres fichiers
│   ├── package.json             ✅ Existe déjà
│   └── node_modules/            ✅ Existe déjà
└── frontend/
    └── ...
```

**Le backend gère déjà :**
- Configuration SharePoint (`SHAREPOINT_SITE_PATH`, etc.)
- Email (SMTP)
- Logging
- CORS
- Secret organisationnel (`RAILSKILLS_ORG_SECRET`)

---

## ➕ Ce qu'on va ajouter

**Nouveau service de tokens SharePoint pour iOS :**

```
backend/
└── src/
    ├── services/
    │   └── tokenService.js        ⭐ NOUVEAU
    ├── routes/
    │   └── sharepoint.js           ⭐ NOUVEAU (ou ajout à existant)
    ├── .env                        ✏️ MODIFIER (ajouter Azure AD)
    └── server.js                   ✏️ MODIFIER (ajouter routes)
```

---

## 📝 Modifications détaillées

### 1. Ajouter dans `backend/src/.env`

**Ajouter à la fin du fichier existant :**

```env
# ============================================================================
# Azure AD - Service de Tokens SharePoint pour iOS (nov 2025)
# ============================================================================

# Ces variables permettent au backend de générer des tokens SharePoint
# pour les clients iOS sans que le Client Secret soit dans l'app mobile

# Tenant ID Azure AD
AZURE_TENANT_ID=4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9

# Application (Client) ID
AZURE_CLIENT_ID=bd394412-97bf-4513-a59f-e023b010dff7

# Client Secret (⚠️ SENSIBLE - même secret que ci-dessus)
# Note: Ce secret est déjà utilisé pour SharePoint, on le réutilise ici
AZURE_CLIENT_SECRET=[VOTRE_CLIENT_SECRET_ICI]
```

**⚠️ Note importante :**
Le `AZURE_CLIENT_SECRET` est probablement le **même** que celui déjà utilisé dans ton backend pour SharePoint. Tu peux réutiliser le même secret.

---

### 2. Créer `backend/src/services/tokenService.js`

Voir la section "À implémenter" dans `PROMPT_CURSOR_BACKEND_EXISTING.md` pour le code complet.

**Ou demander à Cursor AI :**
```
Crée src/services/tokenService.js selon PROMPT_CURSOR_BACKEND_EXISTING.md
```

---

### 3. Créer ou modifier `backend/src/routes/sharepoint.js`

**Si le fichier existe déjà :**
Ajouter les nouvelles routes au fichier existant.

**Si le fichier n'existe pas :**
Le créer avec les 3 endpoints (token, invalidate, stats).

---

### 4. Modifier `backend/src/server.js`

**Ajouter ces lignes :**

```javascript
// Importer les routes SharePoint (après les autres imports)
const sharepointRoutes = require('./routes/sharepoint');

// Monter les routes (après les autres app.use)
app.use('/api/sharepoint', sharepointRoutes);

console.log('📡 Routes SharePoint activées : /api/sharepoint/*');
```

---

## 🔍 Vérifier la compatibilité

### Si le backend utilise déjà SharePoint

**Vérifier dans le code existant :**
- Est-ce qu'il y a déjà des appels à Azure AD ?
- Est-ce qu'il y a déjà un système de tokens ?
- Est-ce qu'il y a déjà `AZURE_CLIENT_SECRET` dans `.env` ?

**Si OUI :**
✅ Parfait ! Réutiliser le même secret et la même config.

**Si NON :**
✅ Ajouter simplement les nouvelles variables.

---

## 📊 Coexistence avec l'existant

### Scénario A : Backend pour RailSkills Web uniquement (avant)

```
Backend actuel:
- Gère les données web
- Génère des rapports PDF
- API pour le frontend web
```

### Scénario B : Backend pour Web + iOS (après)

```
Backend amélioré:
- Gère les données web         ✅ Inchangé
- Génère des rapports PDF       ✅ Inchangé
- API pour le frontend web      ✅ Inchangé
- Service tokens pour iOS       ⭐ NOUVEAU
```

**Aucun conflit, aucune régression ! 🎉**

---

## 🧪 Tests après intégration

### 1. Vérifier que l'existant fonctionne

```bash
# Démarrer le backend
cd backend
npm run dev

# Tester les endpoints existants
curl http://localhost:3000/api/health
# (ou tout autre endpoint existant)
```

### 2. Tester les nouveaux endpoints

```bash
# Nouveau : Obtenir un token
curl -X POST http://localhost:3000/api/sharepoint/token \
  -H "Content-Type: application/json" \
  -d '{"appVersion":"2.0","platform":"iOS"}'

# Nouveau : Stats
curl http://localhost:3000/api/sharepoint/stats
```

---

## ⚠️ Points d'attention

### 1. Client Secret déjà présent ?

Si ton backend a **déjà** une variable pour le Client Secret Azure AD, **réutilise-la** :

```javascript
// Dans tokenService.js, au lieu de :
clientSecret: process.env.AZURE_CLIENT_SECRET

// Utiliser :
clientSecret: process.env.AZURE_CLIENT_SECRET || process.env.EXISTING_SECRET_VAR
```

### 2. Routes existantes

Si `/api/sharepoint` existe déjà :
- Utiliser un autre préfixe : `/api/sharepoint-tokens` ou `/api/ios-tokens`
- Ou fusionner dans le router existant

### 3. Structure TypeScript ?

Si ton backend est en **TypeScript** au lieu de JavaScript :

**Adapter les extensions :**
- `tokenService.js` → `tokenService.ts`
- `sharepoint.js` → `sharepoint.ts`

**Ajouter les types :**
```typescript
interface SharePointToken {
    accessToken: string;
    expiresIn: number;
    tokenType: string;
    cached: boolean;
}
```

---

## 🚀 Commande Cursor AI adaptée

**Pour un backend TypeScript :**

```
Dans le backend TypeScript existant, ajoute un TokenService pour générer des tokens SharePoint pour iOS.

CRÉER (TypeScript):
- src/services/tokenService.ts - Classe avec cache et appels Azure AD
- src/routes/sharepoint.ts - Routes POST /token, POST /token/invalidate, GET /stats
- src/types/sharepoint.ts - Interfaces TypeScript

MODIFIER:
- src/server.ts - Ajouter routes sharepoint
- src/.env - Ajouter AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET

Le service doit obtenir des tokens depuis Azure AD (OAuth 2.0 client credentials flow) et les mettre en cache avec expiration.

Config Azure AD:
- Tenant: 4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9
- Client ID: bd394412-97bf-4513-a59f-e023b010dff7
- Scope: https://graph.microsoft.com/.default

Code en français, ne pas casser l'existant.
```

---

## ✅ Checklist finale

Après ajout par Cursor AI :

- [ ] `tokenService.js` (ou .ts) créé
- [ ] `routes/sharepoint.js` (ou .ts) créé
- [ ] Routes ajoutées au serveur principal
- [ ] Variables Azure AD dans `.env`
- [ ] Template dans `.env.example`
- [ ] Backend redémarre sans erreur
- [ ] Endpoints existants fonctionnent toujours
- [ ] Nouveaux endpoints répondent
- [ ] Token valide retourné
- [ ] Cache fonctionne

---

## 🎉 Résultat

**Backend RailSkills-Web amélioré avec service de tokens pour iOS !**

```
Backend unique qui gère:
✅ RailSkills Web (frontend React/Vue)
✅ API REST pour le web
✅ Génération rapports PDF
✅ Service tokens pour iOS        ⭐ NOUVEAU
✅ Tout centralisé sur le Mac mini
```

---

**Le backend peut servir à la fois le web ET l'app iOS ! 🚀**

**Aucun impact sur l'existant, juste des nouvelles routes en plus.** ✅


