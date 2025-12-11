# 🚀 Prompt Cursor IA - Modifications Backend RailSkills

**À utiliser sur le Mac mini avec Cursor IA**

---

## Contexte

Le backend RailSkills est en production avec redémarrage automatique (PM2).
L'application iOS a été modifiée pour :
1. Obtenir les tokens SharePoint via le backend (sécurité)
2. Synchroniser le secret de chiffrement organisationnel
3. Télécharger automatiquement la checklist depuis SharePoint

## Objectif

Ajouter les endpoints suivants au backend Node.js Express :

---

## ENDPOINTS À AJOUTER

### 1. GET /api/health
```javascript
// Vérifie que le serveur est en ligne
router.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || '1.0.0',
    service: 'RailSkills Backend'
  });
});
```

### 2. POST /api/sharepoint/token (CRITIQUE)
```javascript
// Obtient un token SharePoint via Azure AD
// Le Client Secret reste sur le serveur (sécurité)

const axios = require('axios');

router.post('/sharepoint/token', async (req, res) => {
  try {
    const tenantId = process.env.AZURE_TENANT_ID;
    const clientId = process.env.AZURE_CLIENT_ID;
    const clientSecret = process.env.AZURE_CLIENT_SECRET;
    
    if (!tenantId || !clientId || !clientSecret) {
      console.error('[SharePoint] Configuration Azure AD manquante');
      return res.status(500).json({ 
        error: 'Configuration Azure AD manquante sur le serveur' 
      });
    }
    
    const tokenUrl = `https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/token`;
    
    const params = new URLSearchParams();
    params.append('client_id', clientId);
    params.append('client_secret', clientSecret);
    params.append('scope', 'https://graph.microsoft.com/.default');
    params.append('grant_type', 'client_credentials');
    
    const response = await axios.post(tokenUrl, params, {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
    
    const cttIdentity = req.headers['x-ctt-identity'] || 'anonymous';
    console.log(`[SharePoint] Token généré pour ${cttIdentity}`);
    
    res.json({
      accessToken: response.data.access_token,
      expiresIn: response.data.expires_in,
      tokenType: response.data.token_type
    });
    
  } catch (error) {
    console.error('[SharePoint] Erreur token:', error.response?.data || error.message);
    res.status(500).json({ 
      error: 'Impossible d\'obtenir le token SharePoint',
      details: error.response?.data?.error_description || error.message
    });
  }
});
```

### 3. GET /api/organization/secret
```javascript
// Retourne le secret de chiffrement de l'organisation
router.get('/organization/secret', (req, res) => {
  try {
    const cttIdentity = req.headers['x-ctt-identity'] || 'anonymous';
    
    const organizationSecret = process.env.ORGANIZATION_SECRET || 'RailSkills.SNCF.2024';
    const organizationName = process.env.ORGANIZATION_NAME || 'SNCF Traction';
    
    console.log(`[Organization] Secret demandé par ${cttIdentity}`);
    
    res.json({
      secret: organizationSecret,
      organizationName: organizationName,
      updatedAt: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('[Organization] Erreur:', error.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});
```

### 4. GET /api/organization (optionnel)
```javascript
// Retourne les infos de l'organisation
router.get('/organization', (req, res) => {
  res.json({
    name: process.env.ORGANIZATION_NAME || 'SNCF Traction',
    createdAt: '2024-01-01T00:00:00Z'
  });
});
```

---

## VARIABLES D'ENVIRONNEMENT

Ajouter dans le fichier `.env` :

```bash
# Azure AD Configuration (OBLIGATOIRE)
AZURE_TENANT_ID=4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9
AZURE_CLIENT_ID=bd394412-97bf-4513-a59f-e023b010dff7
AZURE_CLIENT_SECRET=VOTRE_CLIENT_SECRET_ICI

# Organisation
ORGANIZATION_NAME=SNCF Traction
ORGANIZATION_SECRET=VotreSecretDeChiffrementIci2024

# SharePoint
SHAREPOINT_SITE=sncf.sharepoint.com:/sites/railskillsgrpo365
```

⚠️ **IMPORTANT** : Remplacer `VOTRE_CLIENT_SECRET_ICI` par le vrai Client Secret Azure AD !

---

## STRUCTURE DES FICHIERS

```
backend/
├── routes/
│   ├── index.js          # Routes principales
│   ├── sharepoint.js     # Nouveau : routes SharePoint
│   └── organization.js   # Nouveau : routes organisation
├── .env                  # Variables (NE PAS COMMITER)
├── .env.example          # Template (à commiter)
└── server.js             # Point d'entrée
```

---

## SI LE BACKEND UTILISE UN SEUL FICHIER (server.js ou app.js)

Ajouter directement les routes dans le fichier principal :

```javascript
const express = require('express');
const axios = require('axios');
const cors = require('cors');
require('dotenv').config();

const app = express();

app.use(cors());
app.use(express.json());

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Token SharePoint
app.post('/api/sharepoint/token', async (req, res) => {
  // ... code ci-dessus ...
});

// Secret organisationnel
app.get('/api/organization/secret', (req, res) => {
  // ... code ci-dessus ...
});

// Info organisation
app.get('/api/organization', (req, res) => {
  res.json({ name: process.env.ORGANIZATION_NAME || 'SNCF Traction' });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`RailSkills Backend running on port ${PORT}`);
});
```

---

## DÉPENDANCES À VÉRIFIER

```bash
# Vérifier que axios est installé
npm list axios

# Si non installé :
npm install axios
```

---

## APRÈS MODIFICATION

Le serveur redémarre automatiquement (PM2). Vérifier avec :

```bash
# Voir les logs
pm2 logs

# Tester les endpoints
curl http://localhost:3000/api/health
curl -X POST http://localhost:3000/api/sharepoint/token
curl http://localhost:3000/api/organization/secret
```

---

## CHECKLIST DE VALIDATION

- [ ] Endpoint /api/health répond 200
- [ ] Endpoint /api/sharepoint/token retourne un accessToken
- [ ] Endpoint /api/organization/secret retourne le secret
- [ ] Variables .env configurées avec le vrai Client Secret
- [ ] Logs affichent les requêtes
- [ ] Pas d'erreurs dans pm2 logs après 5 minutes

