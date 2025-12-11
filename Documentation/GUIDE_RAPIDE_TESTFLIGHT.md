# ⚡ Guide Rapide - TestFlight Externe

**Référence rapide pour soumettre RailSkills à TestFlight**

---

## 🎯 Étapes Essentielles (15 minutes)

### 1. Vérifier Xcode (2 min)

```
✅ Projet ouvert
✅ Scheme : RailSkills → Release
✅ Destination : "Any iOS Device"
✅ Signing : Automatique activé
✅ Build number incrémenté
```

### 2. Créer l'Archive (5 min)

```
1. Product → Clean Build Folder (⇧⌘K)
2. Product → Archive (⇧⌘B)
3. Attendre la fin
```

### 3. Valider & Uploader (5 min)

```
1. Organizer → Sélectionner archive
2. Validate App → Suivre l'assistant
3. Distribute App → App Store Connect → Upload
4. Attendre la fin
```

### 4. Configurer TestFlight (3 min)

```
1. App Store Connect → TestFlight
2. Attendre le build (10-30 min)
3. Ajouter notes de version
4. Ajouter Privacy Policy URL
5. External Testing → Submit for Review
```

---

## 🔢 Build Number

**À incrémenter AVANT chaque upload :**

- **Actuel** : `2`
- **Prochain** : `3`, puis `4`, `5`, etc.

**Où modifier :**
- Xcode → Projet → General → Build
- OU `project.pbxproj` : `CURRENT_PROJECT_VERSION`
- OU `Info.plist` : `CFBundleVersion`

---

## 📋 Informations Requises

### Notes de Version (Template)

```
Version 1.0 (Build X)

✨ Nouveautés :
- Application RailSkills pour le suivi triennal
- Synchronisation SharePoint
- Interface moderne iOS 18

🐛 Corrections :
- Améliorations de stabilité
```

### Privacy Policy URL

- **Obligatoire** pour TestFlight externe
- URL publique accessible
- En français
- Décrit l'utilisation des données

---

## ⚠️ Erreurs Courantes

| Erreur | Solution |
|--------|----------|
| "No signing certificate" | Xcode → Preferences → Accounts → Download Profiles |
| "Invalid binary" | Vérifier Info.plist permissions |
| "Bundle ID exists" | Utiliser un autre bundle ID ou supprimer l'app existante |
| Build n'apparaît pas | Attendre 30 minutes (traitement Apple) |

---

## 📞 Support

- **Guide complet** : `GUIDE_XCODE_TESTFLIGHT_ETAPE_PAR_ETAPE.md`
- **Checklist** : `CHECKLIST_TESTFLIGHT.md`
- **Privacy Policy** : `PRIVACY_POLICY_TEMPLATE.md`

---

**Temps total : ~15 minutes + attente traitement Apple (10-30 min)**






