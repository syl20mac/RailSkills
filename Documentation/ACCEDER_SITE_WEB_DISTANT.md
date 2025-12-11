# 🔧 Guide : Accéder au Site Web Distant dans Cursor

**Date :** 3 décembre 2025  
**Problème :** RailSkills-Web n'est pas accessible malgré le SSH

---

## 🎯 Solution : Se Connecter via Remote-SSH

Le dossier distant doit être connecté manuellement via Remote-SSH dans Cursor.

---

## 📋 Étapes pour Se Connecter

### Option 1 : Via la Palette de Commandes (Recommandé)

1. **Ouvrez la Palette de Commandes** :
   - **Mac :** `Cmd + Shift + P`
   - **Windows/Linux :** `Ctrl + Shift + P`

2. **Tapez** : `Remote-SSH: Connect to Host...`

3. **Sélectionnez** : `macmini-railskills`

4. **Attendez la connexion** :
   - Cursor va ouvrir une nouvelle fenêtre
   - Une fois connecté, vous verrez `[SSH: macmini-railskills]` dans la barre de titre

5. **Ouvrez le dossier** :
   - `File > Open Folder...`
   - Naviguez vers : `/Users/sylvain/Applications/RailSkills/RailSkills-Web`
   - Cliquez sur "OK"

### Option 2 : Via le Terminal Intégré

1. **Ouvrez un terminal** dans Cursor :
   - **Mac :** `` Ctrl + ` `` (backtick) ou `Terminal > New Terminal`

2. **Connectez-vous via SSH** :
   ```bash
   ssh macmini-railskills
   ```

3. **Naviguez vers le dossier** :
   ```bash
   cd /Users/sylvain/Applications/RailSkills/RailSkills-Web
   ```

4. **Ouvrez Cursor depuis le terminal** (sur le Mac mini) :
   ```bash
   cursor .
   ```
   
   Ou utilisez `code .` si vous avez VS Code installé.

---

## 🔍 Vérifier la Configuration SSH

### Vérifier que la connexion SSH fonctionne

Dans un terminal local, testez :

```bash
ssh macmini-railskills
```

Si ça ne fonctionne pas, vérifiez votre fichier `~/.ssh/config` :

```bash
cat ~/.ssh/config
```

Il devrait contenir :

```
Host macmini-railskills
    HostName 192.168.1.51
    User sylvain
    IdentityFile ~/.ssh/id_rsa
```

---

## 📁 Alternative : Copier les Fichiers Localement

Si le SSH ne fonctionne pas, vous pouvez :

### Option 1 : Utiliser SCP pour Copier le Fichier

1. **Trouvez le fichier d'inscription sur le serveur distant**
2. **Copiez-le localement** :
   ```bash
   scp macmini-railskills:/Users/sylvain/Applications/RailSkills/RailSkills-Web/path/to/file.tsx ./local-copy.tsx
   ```

3. **Modifiez le fichier localement**
4. **Renvoyez-le sur le serveur** :
   ```bash
   scp ./local-copy.tsx macmini-railskills:/Users/sylvain/Applications/RailSkills/RailSkills-Web/path/to/file.tsx
   ```

### Option 2 : Utiliser SFTP

Utilisez un client SFTP comme FileZilla ou Cyberduck pour accéder aux fichiers.

---

## 🎯 Solution Rapide : Modifier Directement via SSH

Si vous avez juste besoin d'ajouter le message rapidement :

1. **Connectez-vous via SSH** :
   ```bash
   ssh macmini-railskills
   ```

2. **Trouvez le fichier d'inscription** :
   ```bash
   cd /Users/sylvain/Applications/RailSkills/RailSkills-Web
   find . -name "*register*.tsx" -o -name "*signup*.tsx"
   ```

3. **Ouvrez le fichier avec un éditeur** :
   ```bash
   nano frontend/src/components/Auth/RegisterForm.tsx
   # ou vim, ou votre éditeur préféré
   ```

4. **Ajoutez le message** en utilisant le code fourni dans les guides

5. **Sauvegardez et quittez**

---

## 🔧 Dépannage

### Problème : "Host key verification failed"

**Solution :** Supprimez la clé de votre fichier `~/.ssh/known_hosts` :
```bash
ssh-keygen -R macmini-railskills
# ou
ssh-keygen -R 192.168.1.51
```

### Problème : "Permission denied"

**Solution :** Vérifiez que votre clé SSH est bien copiée sur le serveur :
```bash
ssh-copy-id macmini-railskills
```

### Problème : "Connection refused"

**Solution :** 
1. Vérifiez que le Mac mini est allumé et sur le même réseau
2. Vérifiez l'IP dans `~/.ssh/config`
3. Testez la connexion : `ping 192.168.1.51`

### Problème : Remote-SSH ne s'installe pas

**Solution :**
1. Dans Cursor, allez dans Extensions
2. Recherchez "Remote - SSH"
3. Installez l'extension officielle de Microsoft

---

## 💡 Workflow Recommandé

Pour éviter les problèmes, voici un workflow recommandé :

### Workflow 1 : Deux Fenêtres (Recommandé)

1. **Fenêtre 1** : Application iOS (locale)
2. **Fenêtre 2** : Site web (distant via Remote-SSH)

**Avantages :**
- Séparation claire des projets
- Pas de confusion
- Chaque fenêtre peut avoir ses propres extensions

### Workflow 2 : Workspace Multi-Root

1. **Ouvrez le workspace** : `RailSkills-Complete.code-workspace`
2. **Connectez-vous d'abord** via Remote-SSH à `macmini-railskills`
3. **Ensuite** ouvrez le workspace

---

## 📝 Résumé Rapide

**Pour accéder au site web :**

1. `Cmd + Shift + P` → `Remote-SSH: Connect to Host...`
2. Sélectionnez `macmini-railskills`
3. Attendez la connexion (nouvelle fenêtre)
4. `File > Open Folder...` → `/Users/sylvain/Applications/RailSkills/RailSkills-Web`

**Alternative rapide :**

1. Ouvrez un terminal
2. `ssh macmini-railskills`
3. Naviguez vers le dossier
4. Utilisez un éditeur directement sur le serveur

---

**Guide créé ! Utilisez Remote-SSH pour accéder au site web. 🔧**









