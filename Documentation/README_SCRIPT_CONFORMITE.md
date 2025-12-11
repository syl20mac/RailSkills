# 🔧 Script de Conformité Apple - Guide Rapide

## ⚡ Utilisation en 3 étapes

### 1️⃣ Sur le Mac mini, ouvrir Terminal

```bash
cd /Users/sylvaingallon/Desktop/DEV/RailSkills/RailSkills
```

### 2️⃣ Exécuter le script

```bash
./apply_apple_compliance.sh
```

### 3️⃣ Confirmer

```
Voulez-vous continuer ? (o/n) : o
```

---

## ✅ Ce que fait le script

| Action | Fichier | Guideline Apple |
|--------|---------|-----------------|
| 🔴 Supprime Client Secret hardcodé | `Configs/AzureADConfig.swift` | 5.1.1 |
| 🟡 Désactive iCloud entitlements | `RailSkills.entitlements` | 2.3.1 |
| 🟡 Désactive push notifications | `Info.plist` | 5.1.1 (iii) |

---

## 💾 Sauvegarde automatique

Le script crée automatiquement une sauvegarde avant toute modification :
```
backup_before_compliance_YYYYMMDD_HHMMSS/
```

---

## 📄 Fichiers créés

Après exécution, tu trouveras :

1. **`RAPPORT_CONFORMITE_*.txt`** - Rapport d'exécution
2. **`backup_before_compliance_*`** - Dossier de sauvegarde
3. **Modifications dans les 3 fichiers** listés ci-dessus

---

## 🚀 Après le script

### Sur Xcode
```bash
open RailSkills.xcodeproj
# Product → Build (Cmd+B)
```

### Dans l'app iPad
```
Réglages → Synchronisation SharePoint → Configurer Azure AD
```

Entrer : `[VOTRE_CLIENT_SECRET_ICI]`

---

## 📚 Documentation complète

- **`INSTRUCTIONS_MAC_MINI.md`** - Instructions détaillées
- **`CONFORMITE_APPLE_APP_STORE.md`** - Rapport de conformité complet
- **`CORRECTIONS_APPLE_APPLIQUEES.md`** - Résumé des corrections

---

## ⚠️ Important

**Le script modifie uniquement 3 fichiers et crée une sauvegarde.**

Pour annuler :
```bash
cp backup_before_compliance_*/AzureADConfig.swift Configs/
cp backup_before_compliance_*/RailSkills.entitlements .
cp backup_before_compliance_*/Info.plist .
```

---

## ✨ Résultat

**✅ Application conforme Apple App Store**  
**✅ Prête pour soumission**  
**✅ Délai review : 24-48h**

---

**Questions ?** Voir `INSTRUCTIONS_MAC_MINI.md` pour plus de détails.


