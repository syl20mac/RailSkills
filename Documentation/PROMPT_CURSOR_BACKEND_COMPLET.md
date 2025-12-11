# 🚀 Prompt Cursor IA - Backend RailSkills + Site Web

## Contexte

Tu travailles sur le backend Node.js et le site web RailSkills. Ces services sont **en production** sur un serveur avec redémarrage automatique (PM2 ou systemd).

L'application iOS RailSkills a été modifiée pour utiliser le backend comme intermédiaire sécurisé pour :
1. **L'authentification Azure AD** (le Client Secret reste sur le serveur)
2. **Le secret organisationnel** (partagé entre tous les CTT d'une organisation)

## 🎯 Objectif

Ajouter les endpoints suivants au backend et mettre à jour le site web si nécessaire.

---

## 📦 PARTIE 1 : Backend - Nouveaux Endpoints

### 1.1 Endpoint Health Check (si pas existant)

```javascript
// GET /api/health
// Vérifie que le serveur est en ligne

router.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || '1.0.0'
  });
});
```

### 1.2 Endpoint Token SharePoint (CRITIQUE)

```javascript
// POST /api/sharepoint/token
// Obtient un token d'accès SharePoint via Azure AD
// Le Client Secret est stocké dans les variables d'environnement

const axios = require('axios');

router.post('/sharepoint/token', async (req, res) => {
  try {
    // Configuration Azure AD depuis les variables d'environnement
    const tenantId = process.env.AZURE_TENANT_ID;
    const clientId = process.env.AZURE_CLIENT_ID;
    const clientSecret = process.env.AZURE_CLIENT_SECRET;
    const scope = 'https://graph.microsoft.com/.default';
    
    if (!tenantId || !clientId || !clientSecret) {
      return res.status(500).json({ 
        error: 'Configuration Azure AD manquante sur le serveur' 
      });
    }
    
    // Obtenir le token depuis Azure AD
    const tokenUrl = `https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/token`;
    
    const params = new URLSearchParams();
    params.append('client_id', clientId);
    params.append('client_secret', clientSecret);
    params.append('scope', scope);
    params.append('grant_type', 'client_credentials');
    
    const response = await axios.post(tokenUrl, params, {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
    
    // Log pour audit (sans le token complet)
    console.log(`[SharePoint] Token généré pour ${req.headers['x-ctt-identity'] || 'anonymous'}`);
    
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

### 1.3 Endpoint Secret Organisationnel

```javascript
// GET /api/organization/secret
// Retourne le secret de chiffrement de l'organisation
// Le secret est stocké dans les variables d'environnement ou en base de données

router.get('/organization/secret', async (req, res) => {
  try {
    const cttIdentity = req.headers['x-ctt-identity'];
    
    // Option 1 : Secret unique pour toute l'organisation (simple)
    const organizationSecret = process.env.ORGANIZATION_SECRET || 'RailSkills.SNCF.2024';
    const organizationName = process.env.ORGANIZATION_NAME || 'SNCF Traction';
    
    // Option 2 : Secret par organisation (si multi-organisations)
    // const org = await Organization.findByMember(cttIdentity);
    // const organizationSecret = org?.secret || 'default';
    // const organizationName = org?.name || 'Organisation';
    
    console.log(`[Organization] Secret demandé par ${cttIdentity || 'anonymous'}`);
    
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

### 1.4 Endpoint Info Organisation (optionnel)

```javascript
// GET /api/organization
// Retourne les informations de l'organisation du CTT

router.get('/organization', async (req, res) => {
  try {
    const cttIdentity = req.headers['x-ctt-identity'];
    
    res.json({
      name: process.env.ORGANIZATION_NAME || 'SNCF Traction',
      members: [], // Liste des CTT si nécessaire
      createdAt: '2024-01-01T00:00:00Z'
    });
    
  } catch (error) {
    res.status(500).json({ error: 'Erreur serveur' });
  }
});
```

### 1.5 Endpoint Checklist par défaut (optionnel)

```javascript
// GET /api/checklists/default
// Retourne la checklist par défaut (si hébergée sur le backend au lieu de SharePoint)

const fs = require('fs');
const path = require('path');

router.get('/checklists/default', (req, res) => {
  try {
    // Chemin vers le fichier checklist sur le serveur
    const checklistPath = path.join(__dirname, '../data/checklists/questions_CFL.json');
    
    if (!fs.existsSync(checklistPath)) {
      return res.status(404).json({ error: 'Checklist par défaut non trouvée' });
    }
    
    const checklist = JSON.parse(fs.readFileSync(checklistPath, 'utf8'));
    
    console.log(`[Checklists] Checklist par défaut demandée par ${req.headers['x-ctt-identity'] || 'anonymous'}`);
    
    res.json(checklist);
    
  } catch (error) {
    console.error('[Checklists] Erreur:', error.message);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});
```

**Note :** L'iPad télécharge actuellement la checklist depuis SharePoint (`RailSkills/Checklists/questions_CFL.json`). Cet endpoint est une alternative si vous voulez héberger la checklist directement sur le backend.

---

## 🔐 PARTIE 2 : Variables d'environnement

Ajouter ces variables dans le fichier `.env` du backend :

```bash
# Azure AD Configuration
AZURE_TENANT_ID=4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9
AZURE_CLIENT_ID=bd394412-97bf-4513-a59f-e023b010dff7
AZURE_CLIENT_SECRET=VOTRE_CLIENT_SECRET_ICI

# Organisation
ORGANIZATION_NAME=SNCF Traction
ORGANIZATION_SECRET=VotreSecretOrganisationnel2024

# SharePoint
SHAREPOINT_SITE=sncf.sharepoint.com:/sites/railskillsgrpo365
```

⚠️ **IMPORTANT** : Ne jamais commiter le fichier `.env` dans Git !

---

## 🌐 PARTIE 3 : Site Web RailSkills (si nécessaire)

### 3.1 Page de configuration admin (optionnel)

Si le site web a une interface admin, ajouter une page pour :
- Visualiser les organisations
- Modifier le secret organisationnel
- Voir les logs de synchronisation

### 3.2 API côté web (si le site fait des appels)

Si le site web utilise aussi SharePoint, il peut utiliser les mêmes endpoints :

```javascript
// Dans le frontend web
const getSharePointToken = async () => {
  const response = await fetch('/api/sharepoint/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  });
  return response.json();
};
```

---

## 📁 PARTIE 4 : Structure des fichiers à modifier

```
backend/
├── routes/
│   ├── index.js          # Ajouter les nouvelles routes
│   ├── sharepoint.js     # Nouveau fichier pour SharePoint
│   └── organization.js   # Nouveau fichier pour Organisation
├── middleware/
│   └── auth.js           # Vérification du header X-CTT-Identity
├── .env                  # Variables d'environnement (NE PAS COMMITER)
└── .env.example          # Template des variables (à commiter)
```

---

## ⚠️ PARTIE 5 : Précautions Production

### 5.1 Avant de modifier

```bash
# 1. Sauvegarder la config actuelle
cp .env .env.backup

# 2. Vérifier le statut du service
pm2 status
# ou
systemctl status railskills-backend
```

### 5.2 Après modification

```bash
# Le redémarrage est automatique, mais vérifier :
pm2 logs railskills
# ou
journalctl -u railskills-backend -f

# Tester les endpoints
curl http://localhost:3000/api/health
curl -X POST http://localhost:3000/api/sharepoint/token
curl http://localhost:3000/api/organization/secret
```

### 5.3 Rollback si problème

```bash
# Restaurer la config
cp .env.backup .env

# Redémarrer
pm2 restart railskills
# ou
systemctl restart railskills-backend
```

---

## ✅ Checklist de validation

- [ ] Endpoint `/api/health` répond 200
- [ ] Endpoint `/api/sharepoint/token` retourne un token valide
- [ ] Endpoint `/api/organization/secret` retourne le secret
- [ ] Variables d'environnement configurées
- [ ] Logs affichent les requêtes
- [ ] Pas d'erreurs dans les logs après 5 minutes
- [ ] Test depuis l'app iOS fonctionne

---

## 🔧 Commandes utiles

```bash
# Voir les logs en temps réel
pm2 logs --lines 100

# Redémarrer le service
pm2 restart all

# Vérifier l'utilisation mémoire
pm2 monit

# Tester un endpoint
curl -X POST http://localhost:3000/api/sharepoint/token \
  -H "Content-Type: application/json" \
  -H "X-CTT-Identity: test@sncf.fr"
```

---

## 📝 Notes importantes

1. **Sécurité** : Le Client Secret Azure AD ne doit JAMAIS être exposé côté client
2. **Logs** : Logger toutes les requêtes pour audit (sans données sensibles)
3. **Rate limiting** : Considérer ajouter un rate limiter sur `/api/sharepoint/token`
4. **CORS** : Vérifier que CORS autorise les requêtes depuis l'app iOS
5. **HTTPS** : S'assurer que le serveur utilise HTTPS en production

