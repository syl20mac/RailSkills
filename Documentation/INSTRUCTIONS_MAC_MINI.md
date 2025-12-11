# 📦 Instructions pour le Mac mini - RailSkills

**Date :** 26 novembre 2025  
**Script :** `apply_apple_compliance.sh`

---

## 🎯 Objectif

Appliquer automatiquement toutes les corrections de conformité Apple App Store sur le Mac mini.

---

## 📋 Prérequis

### Sur le Mac mini

1. ✅ **Xcode installé** (version 14.0+)
2. ✅ **Projet RailSkills cloné**
3. ✅ **Terminal ouvert**
4. ✅ **Droits d'accès au dossier du projet**

---

## 🚀 Utilisation du script

### Étape 1 : Aller dans le dossier du projet

```bash
cd /Users/sylvaingallon/Desktop/DEV/RailSkills/RailSkills
```

**⚠️ IMPORTANT :** Si le chemin est différent sur le Mac mini, modifier la variable `PROJECT_ROOT` dans le script.

### Étape 2 : Vérifier que le script est exécutable

```bash
ls -la apply_apple_compliance.sh
```

Devrait afficher : `-rwxr-xr-x` (le `x` indique qu'il est exécutable)

Si ce n'est pas le cas :
```bash
chmod +x apply_apple_compliance.sh
```

### Étape 3 : Exécuter le script

```bash
./apply_apple_compliance.sh
```

### Étape 4 : Suivre les instructions à l'écran

Le script va :
1. ✅ Vérifier les fichiers nécessaires
2. ✅ Créer une sauvegarde automatique
3. ✅ Appliquer les 3 corrections
4. ✅ Vérifier que tout est OK
5. ✅ Générer un rapport de conformité

---

## 🎨 Aperçu de l'exécution

```
═══════════════════════════════════════════════════════════════
  MISE EN CONFORMITÉ APPLE APP STORE - RailSkills
═══════════════════════════════════════════════════════════════

Ce script va appliquer les corrections suivantes :

  1. Supprimer le Client Secret hardcodé
  2. Désactiver les entitlements iCloud
  3. Désactiver les background notifications

⚠️  Une sauvegarde sera créée automatiquement

═══════════════════════════════════════════════════════════════

Voulez-vous continuer ? (o/n) : o

╔════════════════════════════════════════════════════════════════╗
║  Vérification des prérequis
╚════════════════════════════════════════════════════════════════╝

✅ Répertoire projet trouvé
✅ Tous les fichiers nécessaires sont présents

╔════════════════════════════════════════════════════════════════╗
║  Création de la sauvegarde
╚════════════════════════════════════════════════════════════════╝

✅ Sauvegarde créée dans : backup_before_compliance_20251126_185000

...
```

---

## 📁 Fichiers modifiés

Le script modifie **3 fichiers** :

| Fichier | Modification |
|---------|--------------|
| `Configs/AzureADConfig.swift` | Client Secret → `nil` |
| `RailSkills.entitlements` | iCloud entitlements commentés |
| `Info.plist` | UIBackgroundModes commenté |

---

## 💾 Sauvegarde automatique

### Localisation

Le script crée automatiquement une sauvegarde :
```
RailSkills/backup_before_compliance_YYYYMMDD_HHMMSS/
├── AzureADConfig.swift
├── RailSkills.entitlements
└── Info.plist
```

### Restauration (si besoin)

Pour annuler toutes les modifications :
```bash
cp backup_before_compliance_*/AzureADConfig.swift Configs/
cp backup_before_compliance_*/RailSkills.entitlements .
cp backup_before_compliance_*/Info.plist .
```

---

## 📊 Vérification après exécution

### 1. Compiler le projet

```bash
# Ouvrir Xcode
open RailSkills.xcodeproj

# Ou en ligne de commande
xcodebuild -project RailSkills.xcodeproj -scheme RailSkills build
```

### 2. Vérifier les modifications

**Client Secret :**
```bash
grep "clientSecret" Configs/AzureADConfig.swift
```
Devrait afficher : `static let clientSecret: String? = nil`

**iCloud :**
```bash
grep -A 2 "iCloud supprimés" RailSkills.entitlements
```
Devrait afficher les entitlements commentés

**Background notifications :**
```bash
grep -A 2 "UIBackgroundModes supprimé" Info.plist
```
Devrait afficher UIBackgroundModes commenté

---

## 🔧 Personnalisation du script

### Changer le chemin du projet

Éditer le script :
```bash
nano apply_apple_compliance.sh
```

Modifier la ligne 21 :
```bash
# Avant
PROJECT_ROOT="/Users/sylvaingallon/Desktop/DEV/RailSkills/RailSkills"

# Après (exemple)
PROJECT_ROOT="/Volumes/MacMini/Projects/RailSkills/RailSkills"
```

Sauvegarder : `Ctrl+O` puis `Ctrl+X`

---

## ⚠️ Problèmes courants

### Erreur : "Permission denied"

**Solution :**
```bash
chmod +x apply_apple_compliance.sh
```

### Erreur : "Répertoire projet introuvable"

**Solution :**
Vérifier le chemin dans le script (variable `PROJECT_ROOT`)

### Erreur : "Fichier introuvable"

**Solution :**
Vérifier que vous êtes dans le bon répertoire :
```bash
pwd
ls -la Configs/AzureADConfig.swift
```

---

## 📝 Rapport de conformité

Après exécution réussie, un rapport est généré :
```
RAPPORT_CONFORMITE_YYYYMMDD_HHMMSS.txt
```

### Contenu du rapport

- ✅ Liste des modifications appliquées
- ✅ Guidelines Apple concernées
- ✅ Localisation de la sauvegarde
- ✅ Prochaines étapes
- ✅ Statut de conformité

---

## 🚀 Après l'exécution du script

### 1. Tester dans Xcode

```bash
# Ouvrir le projet
open RailSkills.xcodeproj

# Compiler
# Product → Build (Cmd+B)

# Tester sur simulateur
# Product → Run (Cmd+R)
```

### 2. Configurer SharePoint

Dans l'app :
1. Ouvrir **Réglages**
2. Aller dans **Synchronisation SharePoint**
3. Configurer Azure AD
4. Entrer le Client Secret : `[VOTRE_CLIENT_SECRET_ICI]`
5. Tester la connexion

### 3. Préparer pour App Store

- [ ] Screenshots préparés
- [ ] Description rédigée
- [ ] Privacy Policy disponible
- [ ] Tests sur iPad réel effectués

---

## 📞 Support

### En cas de problème

1. **Vérifier le rapport de conformité** généré par le script
2. **Consulter la sauvegarde** (backup_before_compliance_*)
3. **Vérifier les logs** du script
4. **Contacter l'équipe** avec le message d'erreur exact

### Fichiers de documentation

- `CONFORMITE_APPLE_APP_STORE.md` - Rapport détaillé
- `CORRECTIONS_APPLE_APPLIQUEES.md` - Résumé des corrections
- `RAPPORT_CONFORMITE_*.txt` - Rapport d'exécution

---

## ✅ Checklist finale

Après exécution du script sur le Mac mini :

- [ ] Script exécuté sans erreur
- [ ] Rapport de conformité généré
- [ ] Projet compile dans Xcode
- [ ] SharePoint configurable manuellement
- [ ] Tests réalisés sur simulateur
- [ ] Tests réalisés sur iPad réel
- [ ] Prêt pour soumission App Store

---

## 🎉 Résultat attendu

```
═══════════════════════════════════════════════════════════════
TERMINÉ AVEC SUCCÈS
═══════════════════════════════════════════════════════════════

✅ Toutes les corrections ont été appliquées !

📋 Rapport de conformité disponible dans le projet
💾 Sauvegarde disponible : backup_before_compliance_20251126_185000

🚀 Prochaines étapes :
   1. Ouvrir le projet dans Xcode
   2. Compiler (Cmd+B)
   3. Tester sur iPad
   4. Soumettre à l'App Store

✅ Votre application est maintenant conforme Apple App Store !
```

---

**Script créé le :** 26 novembre 2025  
**Testé sur :** macOS Sonoma 14.0+  
**Compatibilité :** macOS 12.0+ (Monterey et supérieur)


