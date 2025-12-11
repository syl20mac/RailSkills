# 🚀 Démarrage Rapide : Accès au Mac mini dans Cursor

**Pour travailler sur l'app iOS en local et le site web à distance**

---

## ⚡ Configuration en 3 Étapes

### 1️⃣ Configurer SSH (Script Automatique)

```bash
cd "/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills/Documentation"
./SCRIPT_CONFIGURATION_SSH.sh
```

Le script va :
- ✅ Vérifier/créer votre clé SSH
- ✅ Configurer la connexion au Mac mini
- ✅ Tester la connexion

**Vous aurez besoin de :**
- L'adresse IP du Mac mini (ex: `192.168.1.XXX`)
- Votre nom d'utilisateur sur le Mac mini

---

### 2️⃣ Installer l'Extension Remote-SSH dans Cursor

1. **Ouvrir Cursor**
2. **Palette de commandes** : `⌘ + Shift + P`
3. **Taper** : `Extensions: Install Extensions`
4. **Chercher** : `Remote - SSH`
5. **Installer** l'extension

---

### 3️⃣ Se Connecter et Ouvrir le Workspace

#### A. Se connecter au Mac mini

1. **Palette** : `⌘ + Shift + P`
2. **Taper** : `Remote-SSH: Connect to Host...`
3. **Sélectionner** : `macmini-railskills` (ou le nom configuré)
4. **Attendre** la connexion (première fois : quelques secondes)

#### B. Ouvrir le workspace complet

1. **Menu** : `File` → `Open Workspace from File...`
2. **Sélectionner** : `RailSkills-Complete.code-workspace`
3. **Se connecter au Mac mini** (voir étape A) si pas déjà connecté
4. **Ajouter le dossier distant** :
   - Menu : `File` → `Add Folder to Workspace...`
   - Naviguer vers le projet web sur le Mac mini

---

## 📁 Structure du Workspace

```
RailSkills-Complete.code-workspace
├── RailSkills/              ← iOS (Local)
└── RailSkills-Web/          ← Web (Remote via SSH)
```

---

## ✅ Vérification

Après configuration, vous devriez voir dans Cursor :

- 📱 **RailSkills iOS (Local)** - Dossier local accessible
- 🌐 **RailSkills Web (Remote)** - Dossier distant accessible

Cursor IA peut maintenant analyser les deux projets !

---

## 📚 Documentation Complète

Pour plus de détails, voir :
- `GUIDE_CURSOR_ACCES_DISTANT.md` - Guide complet
- `SCRIPT_CONFIGURATION_SSH.sh` - Script d'aide

---

**Bon développement ! 🎉**

