# 🤖 Prompt pour Cursor AI - Implémentation Backend RailSkills

**Projet :** Backend Node.js pour RailSkills  
**Objectif :** Implémenter un serveur sécurisé qui gère les tokens SharePoint  
**Contexte :** Mac mini avec Cursor AI installé  
**Date :** 26 novembre 2025

---

## 📋 Contexte du projet

Je travaille sur **RailSkills**, une application iOS pour la SNCF qui nécessite un backend sécurisé pour gérer les tokens SharePoint via Azure AD.

**Problème à résoudre :**
L'application iOS ne peut pas contenir de Client Secret hardcodé (rejet Apple App Store). Je dois créer un backend qui :
- Stocke le Client Secret Azure AD de manière sécurisée
- Génère des tokens SharePoint pour les clients iOS
- Gère le cache et l'expiration des tokens
- Fournit une API REST simple

**Architecture cible :**
```
iPad iOS → Backend (ce serveur) → Azure AD → SharePoint
```

---

## 🎯 Cahier des charges

### Prérequis techniques

**Stack :**
- Node.js 16+ / Express.js
- Pas de base de données (cache en mémoire)
- Pas d'authentification client (pour MVP, ajout futur)

**Configuration Azure AD existante :**
- Tenant ID : `4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9`
- Client ID : `bd394412-97bf-4513-a59f-e023b010dff7`
- Client Secret : À configurer via .env
- Scope : `https://graph.microsoft.com/.default`

---

## 🔧 Implémentation demandée

### Fichier 1 : `server.js`

**Créer un serveur Express avec les endpoints suivants :**

#### 1. Health Check
```
GET /api/health
```
**Réponse :**
```json
{
  "status": "ok",
  "service": "RailSkills Backend",
  "version": "1.0.0",
  "timestamp": "2025-11-26T18:00:00.000Z"
}
```

#### 2. Obtenir un token SharePoint
```
POST /api/sharepoint/token
```
**Body (optionnel) :**
```json
{
  "appVersion": "2.0",
  "platform": "iOS"
}
```
**Réponse :**
```json
{
  "accessToken": "eyJ0eXAiOiJKV1...",
  "expiresIn": 3599,
  "tokenType": "Bearer",
  "cached": false
}
```

**Logique :**
1. Vérifier le cache (si token valide, le retourner)
2. Si pas de cache ou expiré, demander un nouveau token à Azure AD
3. Mettre en cache avec expiration (token TTL - 5 minutes de marge)
4. Retourner le token au client

**Endpoint Azure AD pour obtenir un token :**
```
POST https://login.microsoftonline.com/{tenantId}/oauth2/v2.0/token

Body (x-www-form-urlencoded):
  grant_type=client_credentials
  client_id={clientId}
  client_secret={clientSecret}
  scope=https://graph.microsoft.com/.default
```

#### 3. Invalider le cache (debug)
```
POST /api/sharepoint/token/invalidate
```
Force le backend à redemander un nouveau token.

#### 4. Statistiques (debug)
```
GET /api/stats
```
Retourne l'état du cache, temps d'expiration, etc.

---

### Fichier 2 : `package.json`

**Dépendances nécessaires :**
```json
{
  "name": "railskills-backend",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.2",
    "axios": "^1.6.0",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  },
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  }
}
```

---

### Fichier 3 : `.env.example`

**Template de configuration :**
```env
# Azure AD Configuration
AZURE_TENANT_ID=4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9
AZURE_CLIENT_ID=bd394412-97bf-4513-a59f-e023b010dff7
AZURE_CLIENT_SECRET=votre_client_secret_ici

# Server Configuration
PORT=3000
NODE_ENV=development
```

---

### Fichier 4 : `.gitignore`

**Protection des secrets :**
```
node_modules/
.env
.env.local
*.log
.DS_Store
```

---

## 🔐 Exigences de sécurité

1. **Client Secret :**
   - JAMAIS hardcodé dans le code
   - Toujours depuis `process.env.AZURE_CLIENT_SECRET`
   - Vérifier au démarrage que la variable existe

2. **Cache de tokens :**
   - En mémoire simple (objet JavaScript)
   - Structure : `{ token: string, expiresAt: timestamp }`
   - Marge de sécurité de 5 minutes avant expiration

3. **Logs :**
   - Logger les demandes de tokens (sans afficher le token lui-même)
   - Logger les erreurs Azure AD
   - Format : `[TIMESTAMP] [LEVEL] Message`

4. **CORS :**
   - Activé pour développement
   - À restreindre en production (origine spécifique)

---

## 📝 Code style et conventions

**Commentaires :**
- En français
- Commentaires de section avec `// ===`
- Commentaires de fonction avec JSDoc

**Exemple :**
```javascript
/**
 * Obtient un token d'accès depuis Azure AD
 * @returns {Promise<{accessToken: string, expiresIn: number}>}
 */
async function getAzureToken() {
  // Implementation
}
```

**Gestion d'erreurs :**
- try/catch pour les appels Azure AD
- Retourner des erreurs HTTP appropriées (500, 401, etc.)
- Messages d'erreur clairs en français

---

## 🧪 Tests à implémenter

**Après création, tester avec curl :**

```bash
# 1. Health check
curl http://localhost:3000/api/health

# 2. Obtenir un token
curl -X POST http://localhost:3000/api/sharepoint/token \
  -H "Content-Type: application/json" \
  -d '{"appVersion":"2.0","platform":"iOS"}'

# 3. Vérifier le cache (2ème appel, devrait être instantané)
curl -X POST http://localhost:3000/api/sharepoint/token \
  -H "Content-Type: application/json" \
  -d '{"appVersion":"2.0","platform":"iOS"}'

# 4. Stats
curl http://localhost:3000/api/stats
```

---

## 📦 Structure de fichiers attendue

```
Backend_RailSkills/
├── server.js              (Serveur Express principal)
├── package.json           (Dépendances et scripts)
├── .env.example           (Template configuration)
├── .env                   (Configuration réelle - ignoré par Git)
├── .gitignore             (Protection des secrets)
└── README.md              (Documentation)
```

---

## ⚙️ Commandes d'installation et démarrage

```bash
# Installation
npm install

# Configuration
cp .env.example .env
nano .env  # Ajouter le Client Secret

# Démarrage développement
npm run dev

# Démarrage production
npm start
```

---

## 🎯 Critères de succès

Le backend est fonctionnel quand :

1. ✅ Le serveur démarre sans erreur
2. ✅ `/api/health` retourne `status: ok`
3. ✅ `/api/sharepoint/token` retourne un token valide
4. ✅ Le cache fonctionne (2ème appel instantané)
5. ✅ Les erreurs Azure AD sont gérées proprement
6. ✅ Le Client Secret n'est jamais exposé dans les logs
7. ✅ Le code est commenté en français
8. ✅ `.env` est ignoré par Git

---

## 🚨 Points d'attention

**Erreurs courantes à éviter :**

1. **Client Secret exposé** → Toujours `process.env`
2. **Pas de vérification de la config** → Vérifier au démarrage
3. **Cache sans expiration** → Ajouter timestamp d'expiration
4. **Logs verbeux** → Ne jamais logger les tokens
5. **CORS trop ouvert** → Documenter la restriction pour prod

---

## 📚 Ressources

**Documentation Azure AD OAuth 2.0 :**
https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-client-creds-grant-flow

**Exemple de requête token Azure AD :**
```bash
curl -X POST https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id={clientId}" \
  -d "client_secret={clientSecret}" \
  -d "scope=https://graph.microsoft.com/.default"
```

---

## 💬 Format de réponse attendu de Cursor AI

Après avoir lu ce prompt, Cursor AI doit :

1. **Créer les fichiers** listés ci-dessus
2. **Implémenter le code** selon les spécifications
3. **Tester** que le serveur démarre
4. **Documenter** les étapes de configuration dans README.md
5. **Confirmer** que tous les critères de succès sont remplis

---

## 🎯 Commande pour Cursor AI

**Copier-coller ce prompt dans Cursor AI (Cmd+K ou Cmd+L) :**

```
Implémente un backend Node.js/Express pour RailSkills selon les spécifications du fichier PROMPT_CURSOR_BACKEND.md présent dans le projet.

Créer :
1. server.js - Serveur Express avec 4 endpoints
2. package.json - Avec dépendances (express, axios, cors, dotenv)
3. .env.example - Template de configuration
4. .gitignore - Protection des secrets
5. README.md - Documentation complète

Exigences :
- Code commenté en français
- Client Secret depuis .env uniquement
- Cache de tokens avec expiration
- Gestion d'erreurs complète
- Tests curl dans README

Le serveur doit obtenir des tokens SharePoint depuis Azure AD et les fournir aux clients iOS via une API REST sécurisée.

Configuration Azure AD :
- Tenant: 4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9
- Client ID: bd394412-97bf-4513-a59f-e023b010dff7
- Scope: https://graph.microsoft.com/.default

Suis exactement les spécifications du fichier PROMPT_CURSOR_BACKEND.md.
```

---

## ✅ Checklist de validation

Après implémentation par Cursor AI, vérifier :

- [ ] Tous les fichiers créés (5 fichiers minimum)
- [ ] `npm install` fonctionne
- [ ] `.env.example` présent
- [ ] `.gitignore` protège `.env`
- [ ] Serveur démarre sur port 3000
- [ ] `/api/health` répond
- [ ] `/api/sharepoint/token` retourne un token
- [ ] Cache fonctionne (logs montrent "cache")
- [ ] Code commenté en français
- [ ] README.md avec instructions complètes

---

## 🎉 Résultat attendu

Un backend Node.js complet, sécurisé et prêt à déployer qui gère les tokens SharePoint pour les clients iOS RailSkills.

**Temps estimé d'implémentation par Cursor AI : 2-5 minutes**

---

**Ce prompt est optimisé pour Cursor AI et contient toutes les informations nécessaires pour une implémentation autonome et complète.**


