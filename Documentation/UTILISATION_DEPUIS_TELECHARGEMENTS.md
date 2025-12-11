# 🚀 Utilisation du script depuis Téléchargements - Mac mini

## 📍 Situation

Le script `apply_apple_compliance.sh` est dans le dossier **Téléchargements** du Mac mini.

---

## ⚡ Méthode 1 : Exécuter directement depuis Téléchargements

### Étape 1 : Ouvrir Terminal sur le Mac mini

**Finder** → **Applications** → **Utilitaires** → **Terminal**

Ou : **Cmd + Espace** → Taper "Terminal"

### Étape 2 : Aller dans Téléchargements

```bash
cd ~/Downloads
```

### Étape 3 : Rendre le script exécutable

```bash
chmod +x apply_apple_compliance.sh
```

### Étape 4 : Modifier le chemin du projet dans le script

**Option A - Avec nano (éditeur terminal) :**
```bash
nano apply_apple_compliance.sh
```

Chercher la ligne 21 :
```bash
PROJECT_ROOT="/Users/sylvaingallon/Desktop/DEV/RailSkills/RailSkills"
```

Remplacer par le chemin réel sur le Mac mini, par exemple :
```bash
PROJECT_ROOT="/Users/macmini/Desktop/DEV/RailSkills/RailSkills"
```

Ou :
```bash
PROJECT_ROOT="/Users/nom_utilisateur/Documents/RailSkills/RailSkills"
```

**Sauvegarder :** `Ctrl+O` puis `Entrée`, puis `Ctrl+X` pour quitter

**Option B - Avec TextEdit (interface graphique) :**
```bash
open -a TextEdit apply_apple_compliance.sh
```

Modifier la ligne 21, puis sauvegarder.

### Étape 5 : Exécuter le script

```bash
./apply_apple_compliance.sh
```

---

## 🎯 Méthode 2 : Copier dans le projet (RECOMMANDÉ)

### Étape 1 : Ouvrir Terminal

### Étape 2 : Copier le script vers le projet

```bash
# Copier depuis Téléchargements vers le projet
cp ~/Downloads/apply_apple_compliance.sh /Users/UTILISATEUR/Desktop/DEV/RailSkills/RailSkills/

# Remplacer UTILISATEUR par ton nom d'utilisateur sur le Mac mini
```

**Exemple :**
```bash
cp ~/Downloads/apply_apple_compliance.sh /Users/macmini/Desktop/DEV/RailSkills/RailSkills/
```

### Étape 3 : Aller dans le projet

```bash
cd /Users/UTILISATEUR/Desktop/DEV/RailSkills/RailSkills
```

### Étape 4 : Modifier le chemin si nécessaire

```bash
nano apply_apple_compliance.sh
```

Ligne 21 : Vérifier/modifier `PROJECT_ROOT`

### Étape 5 : Rendre exécutable et lancer

```bash
chmod +x apply_apple_compliance.sh
./apply_apple_compliance.sh
```

---

## 🔍 Trouver le bon chemin du projet

### Sur le Mac mini, dans Terminal :

```bash
# Méthode 1 : Utiliser Finder
# Glisser-déposer le dossier RailSkills dans Terminal
# Le chemin s'affichera automatiquement

# Méthode 2 : Chercher le projet
find ~ -name "RailSkills.xcodeproj" -type d 2>/dev/null
```

Le résultat affichera le chemin complet, par exemple :
```
/Users/macmini/Desktop/DEV/RailSkills/RailSkills.xcodeproj
```

Le `PROJECT_ROOT` sera :
```
/Users/macmini/Desktop/DEV/RailSkills/RailSkills
```

---

## 📝 Exemple complet sur Mac mini

```bash
# 1. Aller dans Téléchargements
cd ~/Downloads

# 2. Vérifier que le fichier est là
ls -la apply_apple_compliance.sh

# 3. Trouver le projet
find ~ -name "RailSkills.xcodeproj" 2>/dev/null
# Résultat : /Users/macmini/Documents/Projets/RailSkills/RailSkills.xcodeproj

# 4. Modifier le script
nano apply_apple_compliance.sh
# Changer ligne 21 vers : /Users/macmini/Documents/Projets/RailSkills/RailSkills

# 5. Rendre exécutable
chmod +x apply_apple_compliance.sh

# 6. Exécuter
./apply_apple_compliance.sh

# 7. Confirmer
# Voulez-vous continuer ? (o/n) : o

# ✅ Terminé !
```

---

## ⚠️ Erreurs courantes

### Erreur : "command not found"

**Cause :** Le script n'est pas exécutable

**Solution :**
```bash
chmod +x apply_apple_compliance.sh
```

### Erreur : "Répertoire projet introuvable"

**Cause :** Le chemin `PROJECT_ROOT` est incorrect

**Solution :**
```bash
# Trouver le projet
find ~ -name "RailSkills.xcodeproj" 2>/dev/null

# Modifier le script avec le bon chemin
nano apply_apple_compliance.sh
```

### Erreur : "Permission denied"

**Cause :** Pas les droits d'accès au projet

**Solution :**
```bash
# Vérifier les permissions
ls -la /path/to/RailSkills/

# Si nécessaire, ajuster les permissions
chmod -R u+w /path/to/RailSkills/
```

---

## 🎯 Version simplifiée (copier-coller)

```bash
# TOUT EN UNE COMMANDE
cd ~/Downloads && \
chmod +x apply_apple_compliance.sh && \
nano apply_apple_compliance.sh
# (Modifier ligne 21 avec le bon chemin, Ctrl+O, Ctrl+X)

# PUIS
./apply_apple_compliance.sh
```

---

## 📱 Alternative : Utiliser Xcode

Si Terminal est compliqué :

### 1. Ouvrir le projet dans Xcode
```bash
open /path/to/RailSkills/RailSkills.xcodeproj
```

### 2. Modifier manuellement les 3 fichiers

**Fichier 1 : `Configs/AzureADConfig.swift`**
```swift
// Ligne 16 : Changer en
static let clientSecret: String? = nil
```

**Fichier 2 : `RailSkills.entitlements`**
- Commenter toutes les lignes iCloud (ajouter `<!--` et `-->`)

**Fichier 3 : `Info.plist`**
- Commenter la section `UIBackgroundModes`

### 3. Compiler
**Product** → **Build** (Cmd+B)

---

## ✅ Vérification après exécution

```bash
# Vérifier que les changements sont appliqués
cd /path/to/RailSkills/RailSkills

# Client Secret
grep "clientSecret" Configs/AzureADConfig.swift
# Devrait afficher : static let clientSecret: String? = nil

# iCloud
grep "iCloud supprimés" RailSkills.entitlements
# Devrait afficher le commentaire

# Notifications
grep "UIBackgroundModes supprimé" Info.plist
# Devrait afficher le commentaire
```

---

## 🎉 Résultat final

Après exécution réussie :

```
╔════════════════════════════════════════════════════════════════╗
║  TERMINÉ AVEC SUCCÈS
╚════════════════════════════════════════════════════════════════╝

✅ Toutes les corrections ont été appliquées !

📋 Rapport de conformité disponible dans le projet
💾 Sauvegarde disponible : backup_before_compliance_*

🚀 Prochaines étapes :
   1. Ouvrir le projet dans Xcode
   2. Compiler (Cmd+B)
   3. Tester sur iPad
   4. Soumettre à l'App Store

✅ Votre application est maintenant conforme Apple App Store !
```

---

## 📞 Besoin d'aide ?

Si le script ne fonctionne pas, tu peux :

1. **Modifier manuellement** les 3 fichiers dans Xcode (plus simple)
2. **M'envoyer le message d'erreur** exact
3. **Vérifier** que le chemin du projet est correct

---

**Le script est prêt à être utilisé depuis Téléchargements ! 🚀**

**Conseil :** Copier le script dans le projet (Méthode 2) est plus propre.


