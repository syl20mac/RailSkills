# 🔗 Guide : Accès au Répertoire Distant Mac mini dans Cursor

**Date :** 3 décembre 2025  
**Objectif :** Travailler sur l'app iOS en local et le site web à distance dans Cursor IA

---

## 🎯 Vue d'Ensemble

Ce guide vous permet de configurer Cursor pour accéder simultanément à :
- ✅ **Projet iOS local** : `/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills/`
- ✅ **Projet web distant** : Sur le Mac mini (chemin à déterminer)

---

## 📋 Prérequis

### Sur le Mac mini (serveur distant)

1. ✅ **SSH activé**
2. ✅ **Connexion réseau** (même réseau local ou VPN)
3. ✅ **Informations de connexion** :
   - Adresse IP du Mac mini (ex: `192.168.1.XXX`)
   - Nom d'utilisateur SSH
   - Chemin du projet web sur le Mac mini

### Sur votre Mac local

1. ✅ **Cursor installé**
2. ✅ **Accès SSH configuré** (clés SSH recommandées)

---

## 🔧 Configuration SSH (Option 1 - Recommandée)

### Étape 1 : Générer une clé SSH (si nécessaire)

Sur votre Mac local :

```bash
# Générer une clé SSH (si vous n'en avez pas)
ssh-keygen -t ed25519 -C "votre-email@example.com"

# Copier la clé publique vers le Mac mini
ssh-copy-id utilisateur@192.168.1.XXX
```

Remplacez :
- `utilisateur` : Votre nom d'utilisateur sur le Mac mini
- `192.168.1.XXX` : L'adresse IP du Mac mini

### Étape 2 : Tester la connexion SSH

```bash
ssh utilisateur@192.168.1.XXX
```

Si la connexion fonctionne, vous pouvez continuer.

---

## 🚀 Méthode 1 : Workspace Multi-Root dans Cursor

### Création d'un Workspace avec Dossiers Local + Distant

1. **Ouvrir Cursor**

2. **Créer un nouveau workspace** :
   - Menu : `File` → `Save Workspace As...`
   - Nom : `RailSkills-Complete.code-workspace`
   - Enregistrer dans : `/Users/sylvaingallon/Desktop/Railskills rebuild/`

3. **Ajouter le dossier local** :
   - Menu : `File` → `Add Folder to Workspace...`
   - Sélectionner : `/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills/`

4. **Ajouter le dossier distant** :
   - Utiliser l'extension Remote-SSH de Cursor (voir Méthode 2)

---

## 🌐 Méthode 2 : Extension Remote-SSH (Recommandée)

### Installation de l'Extension Remote-SSH

1. **Dans Cursor** :
   - Ouvrir la palette de commandes : `⌘ + Shift + P`
   - Taper : `Extensions: Install Extensions`
   - Chercher : `Remote - SSH`
   - Installer l'extension

### Configuration SSH

1. **Créer/modifier le fichier de configuration SSH** :

```bash
# Sur votre Mac local
nano ~/.ssh/config
```

2. **Ajouter la configuration du Mac mini** :

```ssh-config
Host macmini-railskills
    HostName 192.168.1.XXX
    User sylvaingallon
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

Remplacez :
- `192.168.1.XXX` : L'adresse IP du Mac mini
- `sylvaingallon` : Votre nom d'utilisateur sur le Mac mini
- `~/.ssh/id_ed25519` : Le chemin vers votre clé SSH privée

3. **Sauvegarder** : `Ctrl+O` puis `Ctrl+X`

### Connexion au Mac mini dans Cursor

1. **Ouvrir la palette de commandes** : `⌘ + Shift + P`

2. **Taper** : `Remote-SSH: Connect to Host...`

3. **Sélectionner** : `macmini-railskills`

4. **Attendre la connexion** (première fois, cela peut prendre quelques secondes)

5. **Sélectionner la plateforme** : `macOS`

6. **Ouvrir le dossier** :
   - Menu : `File` → `Open Folder...`
   - Naviguer vers le projet web sur le Mac mini
   - Exemple : `/Users/sylvaingallon/Desktop/DEV/RailSkills-Web/`

---

## 📁 Méthode 3 : Workspace Multi-Root avec SSH

### Créer un Workspace Configuration

Créer un fichier `RailSkills-Complete.code-workspace` :

```json
{
    "folders": [
        {
            "path": "RailSkills",
            "name": "RailSkills iOS (Local)"
        },
        {
            "path": "/Users/sylvaingallon/Desktop/DEV/RailSkills-Web",
            "name": "RailSkills Web (Remote)"
        }
    ],
    "settings": {
        "files.exclude": {
            "**/.DS_Store": true,
            "**/node_modules": true,
            "**/.git": false
        }
    }
}
```

**Note** : Pour utiliser un dossier distant, vous devez d'abord établir une connexion Remote-SSH.

---

## 🔍 Trouver le Chemin du Projet Web sur le Mac mini

### Option A : Via SSH

```bash
# Se connecter au Mac mini
ssh utilisateur@192.168.1.XXX

# Chercher le projet RailSkills-Web
find ~/Desktop -name "*RailSkills*" -type d 2>/dev/null
find ~/Documents -name "*RailSkills*" -type d 2>/dev/null
```

### Option B : Via Finder (Montage réseau)

1. **Dans Finder** :
   - Menu : `Go` → `Connect to Server...` (ou `⌘ + K`)
   - Taper : `smb://192.168.1.XXX` ou `afp://192.168.1.XXX`
   - Se connecter avec vos identifiants

2. **Naviguer** vers le projet web et noter le chemin

---

## 📝 Configuration Recommandée

### Structure du Workspace

```
RailSkills-Complete.code-workspace
├── RailSkills/                    (Local - iOS)
│   ├── RailSkills/
│   │   ├── RailSkillsApp.swift
│   │   ├── Views/
│   │   ├── Services/
│   │   └── ...
│   └── RailSkills.xcodeproj
│
└── RailSkills-Web/                (Remote - Web via SSH)
    ├── server.js
    ├── package.json
    ├── routes/
    ├── public/
    └── ...
```

### Fichier Workspace Complet

Créer `/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills-Complete.code-workspace` :

```json
{
    "folders": [
        {
            "path": "RailSkills",
            "name": "📱 RailSkills iOS (Local)"
        },
        {
            "path": ".",
            "name": "📁 Documentation (Local)"
        }
    ],
    "remote.SSH.remotePlatform": {
        "macmini-railskills": "darwin"
    },
    "settings": {
        "files.exclude": {
            "**/.DS_Store": true,
            "**/node_modules": true,
            "**/DerivedData": true,
            "**/*.xcworkspace/xcuserdata": true,
            "**/.git/objects": false,
            "**/.git/refs": false
        },
        "files.watcherExclude": {
            "**/node_modules/**": true,
            "**/.git/objects/**": true,
            "**/.git/refs/**": true,
            "**/DerivedData/**": true
        }
    }
}
```

---

## 🎯 Utilisation Quotidienne

### Ouvrir le Workspace

1. **Ouvrir Cursor**
2. **Menu** : `File` → `Open Workspace from File...`
3. **Sélectionner** : `RailSkills-Complete.code-workspace`

### Travailler sur l'App iOS

- Les fichiers iOS sont accessibles directement (local)
- Modifications instantanées
- Compilation dans Xcode possible

### Travailler sur le Site Web

1. **Se connecter au Mac mini** via Remote-SSH (voir ci-dessus)
2. **Ouvrir le dossier** du projet web
3. **Modifier les fichiers** - les changements sont synchronisés en temps réel

### Cursor IA et les Fichiers Distants

Cursor IA peut :
- ✅ Analyser les fichiers locaux (iOS)
- ✅ Analyser les fichiers distants (Web) une fois connecté
- ✅ Comprendre la relation entre les deux projets
- ✅ Suggérer des modifications cohérentes

---

## 🔧 Configuration SSH Avancée

### Pour une connexion plus rapide

Dans `~/.ssh/config` :

```ssh-config
Host macmini-railskills
    HostName 192.168.1.XXX
    User sylvaingallon
    IdentityFile ~/.ssh/id_ed25519
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ControlMaster auto
    ControlPath ~/.ssh/control-%h-%p-%r
    ControlPersist 10m
    Compression yes
```

**Avantages** :
- Connexion persistante (plus rapide)
- Compression des données
- Reconnexion automatique

---

## 🛠️ Dépannage

### Problème : Connexion SSH refusée

**Solutions** :

1. **Vérifier que SSH est activé sur le Mac mini** :
   ```bash
   # Sur le Mac mini
   sudo systemsetup -setremotelogin on
   ```

2. **Vérifier le pare-feu** :
   - Préférences Système → Sécurité → Pare-feu
   - Autoriser les connexions entrantes

### Problème : Clé SSH non reconnue

```bash
# Vérifier la clé publique
cat ~/.ssh/id_ed25519.pub

# Copier manuellement vers le Mac mini
ssh-copy-id utilisateur@192.168.1.XXX
```

### Problème : Cursor ne trouve pas les fichiers distants

1. **Vérifier la connexion SSH** :
   ```bash
   ssh macmini-railskills
   ```

2. **Vérifier les permissions** :
   ```bash
   # Sur le Mac mini
   ls -la /chemin/vers/projet
   ```

---

## 📊 Vérification de la Configuration

### Checklist de Configuration

- [ ] SSH configuré et testé
- [ ] Extension Remote-SSH installée dans Cursor
- [ ] Connexion au Mac mini fonctionnelle
- [ ] Dossier iOS local accessible
- [ ] Dossier web distant accessible
- [ ] Workspace créé avec les deux dossiers
- [ ] Cursor IA peut analyser les deux projets

### Test Rapide

1. **Ouvrir le workspace** dans Cursor
2. **Vérifier les dossiers** dans la barre latérale :
   - 📱 RailSkills iOS (Local)
   - 🌐 RailSkills Web (Remote)
3. **Ouvrir un fichier** de chaque projet
4. **Demander à Cursor IA** : "Explique-moi la relation entre l'app iOS et le site web"

---

## 🚀 Prochaines Étapes

Une fois la configuration terminée :

1. **Tester l'accès aux fichiers** des deux projets
2. **Utiliser Cursor IA** pour travailler sur les deux projets simultanément
3. **Développer** avec accès complet aux deux codebases

---

## 📝 Notes Importantes

### Performance

- Les fichiers locaux sont **instantanés**
- Les fichiers distants peuvent avoir une **légère latence** selon la connexion réseau
- Utiliser une connexion **filaire (Ethernet)** si possible pour de meilleures performances

### Sécurité

- ✅ Utiliser des **clés SSH** plutôt que des mots de passe
- ✅ Configurer le **pare-feu** correctement
- ✅ Limiter l'accès SSH aux **adresses IP autorisées** (si nécessaire)

---

**Configuration créée le :** 3 décembre 2025  
**Compatible avec :** Cursor 0.30+  
**Testé sur :** macOS Sonoma 14.0+

