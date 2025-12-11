# 🔐 Backend RailSkills - Serveur de Tokens SharePoint

Backend Node.js sécurisé qui gère le Client Secret Azure AD et fournit des tokens aux clients iOS.

---

## 🎯 Objectif

**Problème :** Le Client Secret ne peut pas être hardcodé dans l'app iOS (rejet Apple).

**Solution :** Un backend qui :
- ✅ Stocke le Client Secret de manière sécurisée
- ✅ Génère des tokens SharePoint pour les clients
- ✅ Permet la rotation des secrets sans recompilation
- ✅ Centralise l'audit des accès

---

## 📋 Prérequis

- **Node.js** 16+ (https://nodejs.org/)
- **npm** ou **yarn**
- **Client Secret Azure AD**

---

## 🚀 Installation

### 1. Installer les dépendances

```bash
cd Backend_Example
npm install
```

### 2. Configurer les variables d'environnement

```bash
# Copier le fichier exemple
cp .env.example .env

# Éditer .env et ajouter le Client Secret
nano .env
```

**Contenu du .env :**
```env
AZURE_TENANT_ID=4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9
AZURE_CLIENT_ID=bd394412-97bf-4513-a59f-e023b010dff7
AZURE_CLIENT_SECRET=[VOTRE_CLIENT_SECRET_ICI]
PORT=3000
NODE_ENV=development
```

### 3. Démarrer le serveur

```bash
# Mode développement (avec auto-reload)
npm run dev

# Ou mode production
npm start
```

**Résultat :**
```
═══════════════════════════════════════════════════════
🚀 Backend RailSkills démarré
═══════════════════════════════════════════════════════
📡 Port: 3000
🔐 Azure Tenant: 4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9
🔐 Client ID: bd394412-97bf-4513-a59f-e023b010dff7
✅ Client Secret: Configuré

Endpoints disponibles:
  GET  http://localhost:3000/api/health
  POST http://localhost:3000/api/sharepoint/token
  GET  http://localhost:3000/api/stats
═══════════════════════════════════════════════════════
```

---

## 🔌 API Endpoints

### 1. Health Check

```bash
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

---

### 2. Obtenir un token SharePoint

```bash
POST /api/sharepoint/token
Content-Type: application/json

{
  "appVersion": "2.0",
  "platform": "iOS"
}
```

**Réponse :**
```json
{
  "accessToken": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "expiresIn": 3599,
  "tokenType": "Bearer",
  "cached": false
}
```

---

### 3. Statistiques (debug)

```bash
GET /api/stats
```

**Réponse :**
```json
{
  "tokenCached": true,
  "tokenExpiresIn": 3245,
  "configValid": true,
  "uptime": 1234.56,
  "timestamp": "2025-11-26T18:00:00.000Z"
}
```

---

## 🧪 Tests

### Test avec curl

```bash
# Health check
curl http://localhost:3000/api/health

# Obtenir un token
curl -X POST http://localhost:3000/api/sharepoint/token \
  -H "Content-Type: application/json" \
  -d '{"appVersion":"2.0","platform":"iOS"}'

# Stats
curl http://localhost:3000/api/stats
```

---

## 🔐 Sécurité

### ✅ Bonnes pratiques implémentées

1. **Client Secret** stocké dans variables d'environnement (.env)
2. **.env** exclu de Git (.gitignore)
3. **CORS** activé (à restreindre en production)
4. **Cache de tokens** (réduit les appels à Azure AD)
5. **Logs** d'audit des demandes

### ⚠️ À ajouter en production

1. **Authentification** des clients (JWT, API Keys)
2. **Rate limiting** (limiter les requêtes)
3. **HTTPS** obligatoire
4. **Monitoring** (logs centralisés)
5. **Rotation automatique** des secrets

---

## 🚀 Déploiement

### Option 1 : Serveur Linux/Mac mini

```bash
# Installer Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Cloner le projet
git clone ...
cd Backend_Example

# Configurer
cp .env.example .env
nano .env

# Installer et démarrer
npm install
npm start
```

### Option 2 : Docker

```bash
# Créer Dockerfile
docker build -t railskills-backend .
docker run -p 3000:3000 --env-file .env railskills-backend
```

### Option 3 : Cloud (Heroku, AWS, Azure)

Configurer les variables d'environnement dans le dashboard cloud.

---

## 📱 Configuration iOS

Dans `BackendTokenService.swift` :

```swift
private var backendURL: String {
    #if DEBUG
    return "http://localhost:3000"  // Développement
    #else
    return "https://backend.railskills.sncf.fr"  // Production
    #endif
}
```

---

## 🔄 Architecture

```
┌─────────────┐
│   iPad iOS  │
│  RailSkills │
└──────┬──────┘
       │ 1. Demande token
       ↓
┌─────────────────────┐
│  Backend (ce code)  │
│  Node.js + Express  │
│  Client Secret 🔐   │
└──────┬──────────────┘
       │ 2. Demande token avec Client Secret
       ↓
┌─────────────────┐
│    Azure AD     │
│ OAuth 2.0 Flow  │
└──────┬──────────┘
       │ 3. Retourne token
       ↓
┌─────────────────┐
│   SharePoint    │
│  Graph API      │
└─────────────────┘
```

---

## 🛠️ Maintenance

### Logs

```bash
# Voir les logs en temps réel
npm run dev

# En production avec PM2
pm2 logs railskills-backend
```

### Rotation du Client Secret

1. Créer un nouveau Client Secret dans Azure Portal
2. Mettre à jour `.env`
3. Redémarrer le serveur
4. ✅ Aucune recompilation iOS nécessaire !

---

## ❓ FAQ

### Le backend est-il obligatoire ?

Non, l'app iOS peut fonctionner sans backend en mode "Client Secret manuel". Le backend est **fortement recommandé** pour :
- ✅ Sécurité (secrets protégés)
- ✅ UX (pas de saisie manuelle)
- ✅ Maintenance (rotation facile)

### Peut-on héberger sur le Mac mini ?

Oui ! Parfait pour un usage interne SNCF.

### Comment sécuriser davantage ?

1. Ajouter authentification (JWT)
2. Limiter les IPs autorisées
3. Activer HTTPS
4. Utiliser Redis pour le cache
5. Monitorer les accès

---

## 📞 Support

En cas de problème :
1. Vérifier que `.env` est configuré
2. Vérifier que Node.js 16+ est installé
3. Consulter les logs du serveur
4. Tester avec `curl` les endpoints

---

**Backend prêt à être déployé ! 🚀**


