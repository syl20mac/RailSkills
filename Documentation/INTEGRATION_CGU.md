# ✅ Intégration des CGU dans l'Application

**Date :** 3 décembre 2025

---

## 🎯 Objectif

Intégrer les Conditions Générales d'Utilisation (CGU) dans l'application RailSkills iOS.

---

## 📦 Fichiers Créés

### 1. Vue des CGU
- **Fichier :** `RailSkills/Views/Settings/TermsOfServiceView.swift`
- **Fonction :** Affiche les Conditions Générales d'Utilisation dans une vue dédiée

### 2. Intégration dans les Paramètres
- **Fichier :** `RailSkills/Views/Settings/SettingsView.swift`
- **Modification :** Ajout d'une section "Légal" avec lien vers les CGU

---

## 📋 Contenu des CGU

Les CGU incluent 11 sections :

1. **Objet** - Description de l'application et acceptation des CGU
2. **Description du Service** - Fonctionnalités de RailSkills
3. **Utilisation et Responsabilités** - Responsabilités de l'utilisateur
4. **Protection des Données Personnelles** - Conformité RGPD
5. **Confidentialité** - Règles de confidentialité
6. **Disponibilité du Service** - Disponibilité et maintenance
7. **Propriété Intellectuelle** - Droits de propriété
8. **Limitation de Responsabilité** - Responsabilités de la SNCF
9. **Modification des CGU** - Processus de modification
10. **Contact** - Informations de contact
11. **Droit Applicable** - Juridiction française

---

## 🔍 Localisation dans l'Application

### Accès aux CGU

**Dans les Paramètres :**
1. Ouvrir l'application RailSkills
2. Aller dans **Réglages**
3. Section **"Légal"**
4. Taper sur **"Conditions Générales d'Utilisation"**

### Emplacement du Code

```swift
// Dans SettingsView.swift - Section "Légal"
Section {
    NavigationLink {
        TermsOfServiceView()
    } label: {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .foregroundStyle(SNCFColors.ceruleen)
                .frame(width: 24)
            
            Text("Conditions Générales d'Utilisation")
                .font(.subheadline)
        }
    }
} header: {
    Text("Légal")
}
```

---

## ✏️ Personnaliser les CGU

### Modifier le Contenu

Pour modifier le contenu des CGU, éditez le fichier :

`RailSkills/Views/Settings/TermsOfServiceView.swift`

Chaque section est définie par :

```swift
sectionView(
    title: "1. Objet",
    content: """
    Votre contenu ici...
    """
)
```

### Ajouter/Modifier une Section

Pour ajouter ou modifier une section :

```swift
// Section 12 : Nouvelle Section
sectionView(
    title: "12. Nouvelle Section",
    content: """
    Contenu de la nouvelle section...
    """
)
```

### Mettre à Jour la Date

Modifiez la date de dernière mise à jour :

```swift
Text("Dernière mise à jour : 3 décembre 2025")
```

---

## 🎨 Design

La vue des CGU utilise :
- **ScrollView** pour le contenu long
- **Sections structurées** avec titre et contenu
- **Couleurs SNCF** pour la cohérence
- **Navigation intégrée** avec bouton fermer

---

## ✅ Fonctionnalités

- ✅ Affichage complet des CGU
- ✅ Navigation depuis les paramètres
- ✅ Design cohérent avec l'application
- ✅ Scroll pour contenu long
- ✅ Bouton fermer pour revenir en arrière

---

## 🔄 Améliorations Possibles

### Option 1 : Acceptation des CGU au Premier Lancement

Créer une vue d'acceptation qui s'affiche lors du premier lancement :

```swift
@AppStorage("cguAccepted") private var cguAccepted: Bool = false
```

### Option 2 : Versioning des CGU

Suivre les versions acceptées par l'utilisateur :

```swift
@AppStorage("cguVersionAccepted") private var cguVersionAccepted: String = ""
```

### Option 3 : CGU dans un Fichier Externe

Charger les CGU depuis un fichier JSON ou markdown pour faciliter les mises à jour.

### Option 4 : CGU en Ligne

Charger les CGU depuis un serveur web pour permettre les mises à jour sans nouvelle version de l'app.

---

## 📝 Structure de la Vue

```
TermsOfServiceView
├── ScrollView
│   ├── En-tête (titre + date)
│   ├── Section 1 : Objet
│   ├── Section 2 : Description
│   ├── Section 3 : Utilisation
│   ├── Section 4 : Données Personnelles
│   ├── Section 5 : Confidentialité
│   ├── Section 6 : Disponibilité
│   ├── Section 7 : Propriété
│   ├── Section 8 : Responsabilité
│   ├── Section 9 : Modification
│   ├── Section 10 : Contact
│   └── Section 11 : Droit Applicable
└── Navigation Bar (titre + bouton fermer)
```

---

## 🔍 Exemple d'Utilisation

### Accès depuis l'Application

1. Ouvrir l'application
2. Aller dans **Réglages**
3. Section **"Légal"**
4. Taper sur **"Conditions Générales d'Utilisation"**
5. Consulter les CGU
6. Taper sur **"Fermer"** pour revenir

---

## ✅ Checklist

- [x] Vue des CGU créée
- [x] Intégrée dans les paramètres
- [x] Design cohérent avec l'application
- [x] Contenu complet et structuré
- [x] Navigation fonctionnelle

---

## 📚 Ressources

- **Vue CGU :** `RailSkills/Views/Settings/TermsOfServiceView.swift`
- **Intégration :** `RailSkills/Views/Settings/SettingsView.swift`

---

**CGU intégrées avec succès ! ✅**

Les utilisateurs peuvent maintenant consulter les Conditions Générales d'Utilisation directement depuis les paramètres de l'application.








