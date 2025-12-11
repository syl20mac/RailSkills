# 🤖 Prompt Cursor AI - Ajouter Token Service au Backend existant

**Projet :** RailSkills-Web (backend existant)  
**Localisation :** `backend/` du projet RailSkills-Web  
**Objectif :** Ajouter un service de tokens SharePoint au backend existant  
**Date :** 26 novembre 2025

---

## 📋 Contexte

Le projet **RailSkills-Web** a déjà un backend fonctionnel dans le répertoire `backend/`.

**Nouvelle fonctionnalité à ajouter :**
Un service de génération de tokens SharePoint pour les clients iOS, afin que le Client Secret reste uniquement côté serveur (conformité Apple App Store).

**Architecture :**
```
iPad iOS → Backend RailSkills-Web (ici) → Azure AD → SharePoint
```

---

## 🎯 À implémenter dans le backend existant

### 1. Créer `backend/src/services/tokenService.js`

**Service de gestion des tokens Azure AD/SharePoint**

Fonctionnalités :
- Obtenir un token d'accès depuis Azure AD
- Cache des tokens avec expiration automatique
- Gestion de la marge de sécurité (5 minutes avant expiration)
- Logs détaillés sans exposer les secrets

**Code attendu :**

```javascript
/**
 * Service de gestion des tokens SharePoint via Azure AD
 * Le Client Secret reste sur le serveur et n'est jamais exposé
 */

class TokenService {
    constructor() {
        this.tokenCache = {
            token: null,
            expiresAt: null
        };
        
        // Configuration Azure AD depuis .env
        this.config = {
            tenantId: process.env.AZURE_TENANT_ID,
            clientId: process.env.AZURE_CLIENT_ID,
            clientSecret: process.env.AZURE_CLIENT_SECRET,
            scope: 'https://graph.microsoft.com/.default'
        };
    }
    
    /**
     * Obtient un token valide (depuis le cache ou Azure AD)
     */
    async getValidToken() {
        // Vérifier le cache
        if (this.isTokenValid()) {
            console.log('✅ Token retourné depuis le cache');
            return {
                accessToken: this.tokenCache.token,
                expiresIn: this.getSecondsUntilExpiration(),
                tokenType: 'Bearer',
                cached: true
            };
        }
        
        // Demander un nouveau token
        console.log('🔄 Demande d\'un nouveau token à Azure AD...');
        return await this.requestNewToken();
    }
    
    /**
     * Vérifie si le token en cache est encore valide
     */
    isTokenValid() {
        if (!this.tokenCache.token || !this.tokenCache.expiresAt) {
            return false;
        }
        // Marge de sécurité de 5 minutes (300 secondes)
        return Date.now() + 300000 < this.tokenCache.expiresAt;
    }
    
    /**
     * Demande un nouveau token à Azure AD
     */
    async requestNewToken() {
        // Implementation avec axios
        // POST vers https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token
        // Body: grant_type, client_id, client_secret, scope
        // Cache le résultat
        // Retourne: { accessToken, expiresIn, tokenType, cached: false }
    }
    
    /**
     * Invalide le cache (force un nouveau token)
     */
    invalidateCache() {
        this.tokenCache = { token: null, expiresAt: null };
        console.log('🗑️  Cache de token invalidé');
    }
    
    /**
     * Obtient les secondes restantes avant expiration
     */
    getSecondsUntilExpiration() {
        if (!this.tokenCache.expiresAt) return 0;
        return Math.floor((this.tokenCache.expiresAt - Date.now()) / 1000);
    }
}

module.exports = new TokenService();
```

---

### 2. Créer `backend/src/routes/sharepoint.js`

**Routes API pour les tokens SharePoint**

```javascript
/**
 * Routes API pour l'accès SharePoint
 * Fournit des tokens aux clients iOS
 */

const express = require('express');
const router = express.Router();
const tokenService = require('../services/tokenService');

/**
 * POST /api/sharepoint/token
 * Obtient un token d'accès SharePoint
 */
router.post('/token', async (req, res) => {
    try {
        const { appVersion, platform } = req.body;
        console.log(`📱 Demande de token depuis ${platform || 'unknown'} v${appVersion || 'unknown'}`);
        
        const token = await tokenService.getValidToken();
        res.json(token);
    } catch (error) {
        console.error('❌ Erreur lors de l\'obtention du token:', error.message);
        res.status(500).json({
            error: 'TOKEN_ERROR',
            message: 'Impossible d\'obtenir un token SharePoint',
            details: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

/**
 * POST /api/sharepoint/token/invalidate
 * Invalide le cache de token
 */
router.post('/token/invalidate', (req, res) => {
    tokenService.invalidateCache();
    res.json({ message: 'Cache invalidé' });
});

/**
 * GET /api/sharepoint/stats
 * Statistiques du cache de tokens (debug)
 */
router.get('/stats', (req, res) => {
    res.json({
        tokenCached: !!tokenService.tokenCache.token,
        tokenExpiresIn: tokenService.getSecondsUntilExpiration(),
        configValid: !!tokenService.config.clientSecret,
        timestamp: new Date().toISOString()
    });
});

module.exports = router;
```

---

### 3. Modifier `backend/src/server.js` (ou index.js)

**Ajouter les routes SharePoint au serveur existant**

```javascript
// Ajouter après les autres imports
const sharepointRoutes = require('./routes/sharepoint');

// Ajouter après les autres routes
app.use('/api/sharepoint', sharepointRoutes);
```

---

### 4. Mettre à jour `backend/src/.env`

**Ajouter les variables Azure AD**

Ajouter ces lignes dans le fichier `.env` existant :

```env
# ============================================================================
# Configuration Azure AD pour tokens SharePoint (ajouté nov 2025)
# ============================================================================

# Azure AD Tenant ID
AZURE_TENANT_ID=4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9

# Azure AD Client ID (App ID)
AZURE_CLIENT_ID=bd394412-97bf-4513-a59f-e023b010dff7

# Azure AD Client Secret (⚠️ SENSIBLE - Ne JAMAIS commiter)
AZURE_CLIENT_SECRET=[VOTRE_CLIENT_SECRET_ICI]
```

---

### 5. Mettre à jour `backend/src/.env.example`

**Ajouter le template Azure AD**

```env
# Azure AD Configuration (pour tokens SharePoint iOS)
AZURE_TENANT_ID=4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9
AZURE_CLIENT_ID=bd394412-97bf-4513-a59f-e023b010dff7
AZURE_CLIENT_SECRET=votre_client_secret_ici
```

---

## 🔧 Dépendances à ajouter

Si pas déjà présentes dans `package.json` :

```json
{
  "dependencies": {
    "axios": "^1.6.0"
  }
}
```

Installer avec :
```bash
cd backend
npm install axios
```

---

## 🧪 Tests à effectuer

Après implémentation :

```bash
# 1. Redémarrer le backend
cd backend
npm run dev

# 2. Tester le nouveau endpoint
curl -X POST http://localhost:3000/api/sharepoint/token \
  -H "Content-Type: application/json" \
  -d '{"appVersion":"2.0","platform":"iOS"}'

# 3. Vérifier le cache (2ème appel)
curl -X POST http://localhost:3000/api/sharepoint/token \
  -H "Content-Type: application/json" \
  -d '{"appVersion":"2.0","platform":"iOS"}'
# Devrait afficher "cached": true et être instantané

# 4. Stats
curl http://localhost:3000/api/sharepoint/stats
```

---

## 📁 Structure de fichiers attendue

```
backend/
├── src/
│   ├── services/
│   │   └── tokenService.js       ← NOUVEAU (à créer)
│   ├── routes/
│   │   └── sharepoint.js          ← NOUVEAU (à créer)
│   ├── server.js (ou index.js)    ← MODIFIER (ajouter routes)
│   ├── .env                       ← MODIFIER (ajouter Azure AD)
│   └── .env.example               ← MODIFIER (ajouter template)
├── package.json                   ← VÉRIFIER (axios présent)
└── ...autres fichiers existants
```

---

## ✅ Critères de succès

- [ ] `tokenService.js` créé avec cache et gestion tokens
- [ ] `routes/sharepoint.js` créé avec 3 endpoints
- [ ] Routes ajoutées au serveur principal
- [ ] `.env` contient AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET
- [ ] `.env.example` mis à jour
- [ ] `axios` dans les dépendances
- [ ] Serveur redémarre sans erreur
- [ ] `/api/sharepoint/token` retourne un token valide
- [ ] Cache fonctionne (logs montrent "cache")
- [ ] Code commenté en français

---

## 🚨 Points d'attention spécifiques

### Respecter la structure existante
- Ne PAS écraser les fichiers existants
- Ajouter les nouvelles routes aux routes existantes
- Suivre les conventions de code du projet

### Sécurité
- Client Secret uniquement depuis `process.env.AZURE_CLIENT_SECRET`
- Vérifier au démarrage que la variable existe
- Ne JAMAIS logger les tokens ou secrets

### Compatibilité
- Ne pas casser les fonctionnalités existantes
- Tester que le backend existant fonctionne toujours

---

## 🎯 Prompt court pour Cursor AI

**Copier-coller dans Cursor (Cmd+L) :**

```
Dans le projet RailSkills-Web/backend existant, ajoute un service de tokens SharePoint pour les clients iOS.

CRÉER:
1. src/services/tokenService.js - Classe TokenService avec cache et appels Azure AD
2. src/routes/sharepoint.js - Routes: POST /token, POST /token/invalidate, GET /stats

MODIFIER:
3. src/server.js - Ajouter: app.use('/api/sharepoint', sharepointRoutes)
4. src/.env - Ajouter: AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET
5. src/.env.example - Ajouter template Azure AD

LOGIQUE tokenService:
- Cache: { token: null, expiresAt: null }
- getValidToken(): vérifie cache, sinon appelle Azure AD
- requestNewToken(): POST https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token
  Body (urlencoded): grant_type=client_credentials, client_id, client_secret, scope=https://graph.microsoft.com/.default
- Cache avec marge de 5 min avant expiration

CONFIG AZURE AD:
Tenant: 4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9
Client ID: bd394412-97bf-4513-a59f-e023b010dff7
Client Secret: depuis AZURE_CLIENT_SECRET (.env)

EXIGENCES:
- Code en français
- Ne pas casser l'existant
- axios pour appels HTTP
- Logs sans exposer tokens
- Gestion d'erreurs complète

TEST:
curl -X POST http://localhost:3000/api/sharepoint/token -H "Content-Type: application/json" -d '{"appVersion":"2.0","platform":"iOS"}'
```

---

**Cursor AI va ajouter le service de tokens au backend existant sans rien casser ! 🎯**


