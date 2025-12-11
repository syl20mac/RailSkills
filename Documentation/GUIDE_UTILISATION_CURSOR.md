# 🎯 Guide d'utilisation Cursor AI sur le Mac mini

**Objectif :** Générer le backend RailSkills avec Cursor AI

---

## 📋 Prérequis

Sur le Mac mini :
- ✅ Cursor AI installé
- ✅ Node.js 16+ installé
- ✅ Terminal ouvert

---

## 🚀 Méthode 1 : Prompt court (RAPIDE)

### Étape 1 : Ouvrir Cursor AI

```bash
# Dans Terminal
cd ~/Desktop
mkdir Backend_RailSkills
cd Backend_RailSkills
cursor .
```

Ou double-cliquer sur l'icône Cursor.

---

### Étape 2 : Ouvrir le chat Cursor

**Raccourci clavier :** `Cmd + L` (pour le chat)

Ou cliquer sur l'icône de chat en bas à droite.

---

### Étape 3 : Copier-coller le prompt

**Copier TOUT le contenu du fichier `PROMPT_CURSOR_COURT.txt`**

Ou copier directement ce texte :

```
Implémente un backend Node.js/Express pour RailSkills qui gère les tokens SharePoint.

CONTEXTE:
Application iOS RailSkills ne peut pas avoir de Client Secret hardcodé (rejet Apple).
Le backend doit obtenir des tokens depuis Azure AD et les fournir aux clients iOS.

Architecture: iPad → Backend (ce serveur) → Azure AD → SharePoint

CRÉER:
1. server.js - Serveur Express
2. package.json - Dépendances (express, axios, cors, dotenv)
3. .env.example - Template config
4. .gitignore - Protection secrets
5. README.md - Documentation

ENDPOINTS À IMPLÉMENTER:

1. GET /api/health
   Retourne: { status: "ok", service: "RailSkills Backend", version: "1.0.0", timestamp }

2. POST /api/sharepoint/token
   Body: { appVersion, platform } (optionnel)
   Retourne: { accessToken, expiresIn, tokenType, cached }
   
   Logique:
   - Vérifier cache (si token valide, retourner)
   - Sinon, appeler Azure AD:
     POST https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token
     Body (x-www-form-urlencoded):
       grant_type=client_credentials
       client_id={clientId}
       client_secret={clientSecret}
       scope=https://graph.microsoft.com/.default
   - Mettre en cache (avec expiration - 5 min de marge)
   - Retourner token

3. POST /api/sharepoint/token/invalidate
   Invalide le cache

4. GET /api/stats
   Retourne état du cache

CONFIGURATION AZURE AD:
Tenant ID: 4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9
Client ID: bd394412-97bf-4513-a59f-e023b010dff7
Client Secret: depuis .env uniquement (AZURE_CLIENT_SECRET)
Scope: https://graph.microsoft.com/.default

EXIGENCES:
- Code commenté en français
- Client Secret JAMAIS hardcodé (toujours process.env)
- Vérifier que AZURE_CLIENT_SECRET existe au démarrage
- Cache simple en mémoire: { token: string, expiresAt: timestamp }
- Logs des demandes (sans afficher les tokens)
- Gestion d'erreurs complète (try/catch)
- CORS activé
- Port 3000

STRUCTURE .env:
AZURE_TENANT_ID=4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9
AZURE_CLIENT_ID=bd394412-97bf-4513-a59f-e023b010dff7
AZURE_CLIENT_SECRET=votre_client_secret_ici
PORT=3000
NODE_ENV=development

SCRIPTS package.json:
"start": "node server.js"
"dev": "nodemon server.js"

TESTS CURL À INCLURE DANS README:
curl http://localhost:3000/api/health
curl -X POST http://localhost:3000/api/sharepoint/token -H "Content-Type: application/json" -d '{"appVersion":"2.0","platform":"iOS"}'

CRITÈRES DE SUCCÈS:
✅ Serveur démarre sans erreur
✅ /api/health répond
✅ /api/sharepoint/token retourne un token valide
✅ Cache fonctionne (2ème appel instantané)
✅ Client Secret jamais exposé
✅ Code en français
✅ .env ignoré par Git
```

---

### Étape 4 : Attendre la génération

Cursor AI va :
1. ✅ Analyser le prompt
2. ✅ Créer les fichiers
3. ✅ Écrire le code
4. ✅ Proposer les changements

**Temps estimé : 30 secondes - 2 minutes**

---

### Étape 5 : Accepter les changements

Cursor AI va proposer :
- `server.js`
- `package.json`
- `.env.example`
- `.gitignore`
- `README.md`

**Cliquer sur "Accept" ou "Apply"** pour chaque fichier.

---

### Étape 6 : Configuration

```bash
# Installer les dépendances
npm install

# Copier le template .env
cp .env.example .env

# Éditer .env et ajouter le Client Secret
nano .env
```

Dans `.env`, modifier :
```env
AZURE_CLIENT_SECRET=[VOTRE_CLIENT_SECRET_ICI]
```

Sauvegarder : `Ctrl+O`, puis `Ctrl+X`

---

### Étape 7 : Démarrer le serveur

```bash
npm run dev
```

**Résultat attendu :**
```
🚀 Backend RailSkills démarré
📡 Port: 3000
✅ Client Secret: Configuré
```

---

### Étape 8 : Tester

```bash
# Dans un nouveau terminal
curl http://localhost:3000/api/health

curl -X POST http://localhost:3000/api/sharepoint/token \
  -H "Content-Type: application/json" \
  -d '{"appVersion":"2.0","platform":"iOS"}'
```

---

## 🎯 Méthode 2 : Prompt détaillé (COMPLET)

Si la méthode 1 ne suffit pas, utiliser le prompt complet :

### Étape 1-2 : Comme méthode 1

### Étape 3 : Dans Cursor AI

**Taper :**
```
@PROMPT_CURSOR_BACKEND.md Implémente le backend selon les spécifications de ce fichier
```

Cursor AI lira le fichier `PROMPT_CURSOR_BACKEND.md` qui contient toutes les spécifications détaillées.

---

## 🔧 Si Cursor AI ne génère pas tout

### Demander fichier par fichier

**Dans le chat Cursor (`Cmd+L`) :**

1. **Pour server.js :**
```
Crée server.js avec un serveur Express qui :
- Écoute sur port 3000
- Endpoint GET /api/health
- Endpoint POST /api/sharepoint/token qui obtient un token depuis Azure AD
- Cache de tokens avec expiration
- Code commenté en français
```

2. **Pour package.json :**
```
Crée package.json avec :
- express, axios, cors, dotenv en dependencies
- nodemon en devDependencies
- scripts "start" et "dev"
```

3. **Pour .env.example :**
```
Crée .env.example avec AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, PORT, NODE_ENV
```

4. **Pour .gitignore :**
```
Crée .gitignore qui protège .env, node_modules/, *.log
```

5. **Pour README.md :**
```
Crée README.md avec instructions d'installation, configuration et tests curl
```

---

## 💡 Astuces Cursor AI

### Sélectionner du code et demander des modifications

1. **Sélectionner** une fonction dans `server.js`
2. **`Cmd+K`** (inline edit)
3. **Demander :** "Ajoute des logs en français ici"

### Demander des explications

**`Cmd+L`** puis :
```
Explique-moi comment fonctionne la fonction getAzureToken
```

### Corriger des erreurs

Si erreur lors du démarrage :
```
@server.js J'ai cette erreur : [coller l'erreur]. Comment la corriger ?
```

---

## 🐛 Résolution de problèmes

### Erreur : "Client Secret not configured"

```bash
# Vérifier que .env existe
ls -la .env

# Vérifier le contenu
cat .env

# S'assurer que AZURE_CLIENT_SECRET est défini
grep AZURE_CLIENT_SECRET .env
```

### Erreur : "npm install" échoue

```bash
# Nettoyer et réinstaller
rm -rf node_modules package-lock.json
npm install
```

### Erreur : "Port 3000 already in use"

```bash
# Trouver le processus
lsof -i :3000

# Tuer le processus
kill -9 [PID]

# Ou changer le port dans .env
echo "PORT=3001" >> .env
```

### Cursor AI ne répond pas

1. **Recharger Cursor :** `Cmd+R`
2. **Vérifier la connexion** Internet
3. **Vérifier le quota** Cursor AI

---

## ✅ Checklist de validation

Après génération par Cursor AI :

- [ ] `server.js` créé et contient les 4 endpoints
- [ ] `package.json` avec bonnes dépendances
- [ ] `.env.example` présent
- [ ] `.gitignore` protège `.env`
- [ ] `README.md` avec instructions
- [ ] `npm install` fonctionne
- [ ] `.env` configuré avec Client Secret
- [ ] `npm run dev` démarre le serveur
- [ ] `/api/health` répond
- [ ] `/api/sharepoint/token` retourne un token
- [ ] Code commenté en français

---

## 🎉 Résultat attendu

Backend Node.js complet en **2-5 minutes** grâce à Cursor AI ! 🚀

```
Backend_RailSkills/
├── server.js           ✅ Généré par Cursor
├── package.json        ✅ Généré par Cursor
├── .env.example        ✅ Généré par Cursor
├── .env                ✅ À créer manuellement
├── .gitignore          ✅ Généré par Cursor
├── README.md           ✅ Généré par Cursor
└── node_modules/       ✅ Créé par npm install
```

---

## 📞 Support

Si Cursor AI ne génère pas bien le code :
1. Essayer de reformuler la demande
2. Demander fichier par fichier
3. Utiliser le prompt détaillé (PROMPT_CURSOR_BACKEND.md)
4. Me contacter avec les erreurs rencontrées

---

**Bonne génération avec Cursor AI ! 🤖✨**


