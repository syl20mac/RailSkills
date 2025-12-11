# ✅ Checklist TestFlight Externe - RailSkills

**Date :** 3 décembre 2025

---

## 🎯 Modifications Nécessaires

### 1. 🔢 Incrémenter le Build Number (OBLIGATOIRE)

**Fichiers à modifier :**

#### `RailSkills.xcodeproj/project.pbxproj`
- Chercher : `CURRENT_PROJECT_VERSION = 1;`
- Changer en : `CURRENT_PROJECT_VERSION = 2;`
- **Faire ça dans les 2 configurations (Debug et Release)**

#### `Configs/Info.plist`
- Chercher : `<key>CFBundleVersion</key>`
- Changer : `<string>1</string>` → `<string>2</string>`

**⚠️ À faire AVANT chaque upload TestFlight !**

---

### 2. 🆔 App Store Connect (OBLIGATOIRE)

**Créer l'app dans App Store Connect :**

1. Aller sur https://appstoreconnect.apple.com
2. My Apps → "+" → New App
3. Remplir :
   - **Platform** : iOS
   - **Name** : RailSkills
   - **Primary Language** : French
   - **Bundle ID** : `com.railskills.syl20.org.RailSkills`
   - **SKU** : `RailSkills-iOS-001`

---

### 3. 📄 Privacy Policy URL (OBLIGATOIRE pour TestFlight Externe)

**Créer une page de politique de confidentialité :**

- URL publique (ex: `https://votresite.com/privacy-policy`)
- En français
- Décrit l'utilisation des données
- Accessible sans authentification

**À ajouter dans App Store Connect :**
- My Apps → RailSkills → App Information
- Privacy Policy URL : [votre URL]

---

### 4. 📝 Notes de Version (RECOMMANDÉ)

**Pour chaque build dans TestFlight :**

```
Version 1.0 (Build 2)

✨ Nouveautés :
- Améliorations iOS 18
- Design moderne

🐛 Corrections :
- Améliorations diverses
```

---

## ✅ Ce qui est Déjà Prêt

- ✅ Bundle identifier configuré
- ✅ Pas de secrets hardcodés
- ✅ Privacy descriptions dans Info.plist
- ✅ App icon complet
- ✅ Configuration iOS 18

---

## 🚀 Actions Immédiates

1. **Incrémenter build number** (2 fichiers)
2. **Créer l'app dans App Store Connect**
3. **Préparer Privacy Policy URL**
4. **Créer l'archive Release**
5. **Uploader vers App Store Connect**

---

**3 modifications principales à faire avant le premier upload ! 🚀**









