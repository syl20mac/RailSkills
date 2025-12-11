# ✅ Solution : Bundle Identifier Manquant

**Date :** 3 décembre 2025  
**Erreur :** `Missing bundle ID. Domain: IXErrorDomain Code: 13`

---

## 🔍 Diagnostic

Le bundle identifier est **déjà présent** dans :
- ✅ `Configs/Info.plist` : `com.railskills.syl20.org.RailSkills`
- ✅ `project.pbxproj` : `PRODUCT_BUNDLE_IDENTIFIER = com.railskills.syl20.org.RailSkills`

Le problème vient probablement d'un **cache de build** ou d'une **synchronisation Xcode**.

---

## ✅ Solution

### Étape 1 : Nettoyer le Build dans Xcode

1. **Ouvrir Xcode**
2. **Product → Clean Build Folder** (⇧⌘K)
3. **Attendre la fin du nettoyage**

### Étape 2 : Nettoyer le DerivedData

Le DerivedData a déjà été nettoyé automatiquement, mais vous pouvez le faire manuellement :

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/RailSkills-*
```

### Étape 3 : Vérifier dans Xcode

1. **Sélectionner le projet** "RailSkills" dans le navigateur
2. **Sélectionner la cible** "RailSkills"
3. **Onglet "General"** :
   - Vérifier que **Bundle Identifier** = `com.railskills.syl20.org.RailSkills`
4. **Onglet "Build Settings"** :
   - Rechercher "Product Bundle Identifier"
   - Vérifier la valeur : `com.railskills.syl20.org.RailSkills`
   - Rechercher "Info.plist File"
   - Vérifier : `Configs/Info.plist`

### Étape 4 : Reconstruire

1. **Product → Build** (⌘B)
2. **Vérifier qu'il n'y a pas d'erreurs**

### Étape 5 : Réessayer dans le Simulateur

1. **Sélectionner un simulateur iPad**
2. **Product → Run** (⌘R)

---

## 🔧 Si le Problème Persiste

### Vérifier le Bundle ID dans Xcode

1. Ouvrir Xcode
2. Sélectionner le projet → Cible "RailSkills"
3. Onglet "Signing & Capabilities"
4. Vérifier/mettre à jour le Bundle Identifier si nécessaire

### Vérifier le Fichier Info.plist

Le fichier doit contenir :
```xml
<key>CFBundleIdentifier</key>
<string>com.railskills.syl20.org.RailSkills</string>
```

### Solution Alternative : Générer Info.plist Automatiquement

Si le problème persiste, vous pouvez laisser Xcode générer Info.plist :

1. Dans **Build Settings**, mettre `GENERATE_INFOPLIST_FILE = YES`
2. Mais dans ce cas, il faut ajouter toutes les clés nécessaires dans les Build Settings

---

## ✅ Vérification Finale

Après nettoyage et reconstruction, vérifier :

```bash
# Vérifier le bundle ID dans Info.plist
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" Configs/Info.plist
# Doit afficher : com.railskills.syl20.org.RailSkills
```

---

**Le bundle identifier est configuré. Nettoyez le build et réessayez ! 🚀**









