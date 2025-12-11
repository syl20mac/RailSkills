# Support RailSkills

**Application :** RailSkills  
**Version :** 1.2+  
**Plateforme :** iOS 18+ / iPadOS 18+  
**Dernière mise à jour :** 9 décembre 2025

---

## 📞 Contact

Pour toute question, problème technique ou demande d'assistance :

**Email :** RailSkills@syl20.org  
**Développeur :** Sylvain GALLON  
**Application :** RailSkills

---

## 🚀 Démarrage Rapide

### Première Utilisation

1. **Lancer l'application** RailSkills
2. **Choisir un mode d'accès :**
   - **Mode démonstration** : Pour tester l'application avec des données de démo
   - **Authentification Azure AD** : Pour utiliser l'application avec votre compte SNCF
3. **Importer ou créer une checklist :**
   - Télécharger depuis SharePoint (si configuré)
   - Importer un fichier JSON
   - Créer une nouvelle checklist vide
4. **Ajouter des conducteurs** depuis l'onglet "Conducteurs"
5. **Commencer le suivi** dans les onglets Suivi, VP ou TE

---

## 📋 Fonctionnalités Principales

### Suivi des Conducteurs

RailSkills permet de gérer le suivi réglementaire des conducteurs avec **3 types de checklists** :

- **Suivi (Triennale)** : Suivi triennal réglementaire
- **VP (Visite Périodique)** : Visites périodiques
- **TE (Test d'Évaluation)** : Tests d'évaluation

### Fonctionnalités Disponibles

- ✅ Gestion des conducteurs (ajout, modification, suppression)
- ✅ Suivi des évaluations par checklist
- ✅ Notes et dates de suivi par question
- ✅ Dashboard avec graphiques de progression
- ✅ Export/Import de données (JSON, PDF)
- ✅ Synchronisation SharePoint (optionnelle)
- ✅ Recherche dans les notes et données
- ✅ Génération de rapports PDF

---

## ❓ Questions Fréquentes (FAQ)

### Configuration et Installation

**Q : Comment configurer la synchronisation SharePoint ?**  
R : Allez dans Réglages → Synchronisation SharePoint → Configuration Azure AD. Vous devrez saisir :
- Client ID
- Tenant ID  
- Client Secret

Ces informations sont fournies par votre administrateur SNCF.

**Q : L'application fonctionne-t-elle sans SharePoint ?**  
R : Oui, RailSkills fonctionne entièrement en mode local. La synchronisation SharePoint est optionnelle.

**Q : Quelles versions d'iOS sont supportées ?**  
R : RailSkills nécessite iOS 18.0 ou supérieur, et iPadOS 18.0 ou supérieur.

### Utilisation

**Q : Comment ajouter un conducteur ?**  
R : Allez dans l'onglet "Conducteurs" → Cliquez sur le bouton "+" → Remplissez les informations (nom obligatoire, prénom et CP optionnels).

**Q : Comment importer une checklist ?**  
R : Dans l'onglet Suivi/VP/TE, si aucune checklist n'est chargée, vous pouvez :
- Télécharger depuis SharePoint (si configuré)
- Importer un fichier JSON depuis l'app Fichiers
- Créer une nouvelle checklist vide

**Q : Comment exporter les données ?**  
R : Réglages → Export/Import → Exporter les données. Les données sont exportées au format JSON (avec compression et chiffrement optionnels).

**Q : Les données sont-elles sauvegardées automatiquement ?**  
R : Oui, toutes les modifications sont sauvegardées automatiquement localement. Si SharePoint est activé, la synchronisation se fait automatiquement (avec débouncing pour éviter les synchronisations excessives).

### Problèmes Techniques

**Q : L'application se ferme soudainement (crash)**  
R : 
1. Vérifiez que vous utilisez iOS 18.0 ou supérieur
2. Redémarrez l'application
3. Si le problème persiste, contactez le support avec les détails de l'erreur

**Q : La synchronisation SharePoint ne fonctionne pas**  
R : 
1. Vérifiez votre connexion Internet
2. Vérifiez que les identifiants Azure AD sont corrects dans Réglages
3. Vérifiez que vous avez accès au site SharePoint SNCF
4. Essayez de vous déconnecter et reconnecter

**Q : Je ne vois pas mes données après la synchronisation**  
R : 
1. Vérifiez que vous utilisez le même compte Azure AD
2. Les données sont filtrées par Manager Traction (`ownerSNCFId`) - assurez-vous que vos données ont le bon identifiant
3. Vérifiez dans Réglages → Synchronisation SharePoint que la synchronisation est activée

**Q : Comment réinitialiser l'application ?**  
R : Réglages → Réinitialiser toutes les données. **Attention :** Cette action supprime toutes les données locales. Les données SharePoint ne sont pas affectées.

### Permissions

**Q : Pourquoi l'application demande l'accès au microphone ?**  
R : Le microphone est utilisé uniquement pour la dictée vocale des notes d'évaluation. Aucun enregistrement audio n'est stocké, seule la transcription est sauvegardée.

**Q : Pourquoi l'application demande l'accès à la reconnaissance vocale ?**  
R : La reconnaissance vocale permet de dicter les notes dans les évaluations. Le traitement est effectué localement sur votre appareil.

---

## 🐛 Problèmes Courants et Solutions

### Checklist non chargée

**Symptôme :** Message "Pas de checklist chargée" dans un onglet (Suivi, VP ou TE)

**Solutions :**
1. Télécharger depuis SharePoint (si configuré) : Cliquez sur "Télécharger depuis SharePoint"
2. Importer un fichier JSON : Cliquez sur "Importer un fichier"
3. Créer une nouvelle checklist : Cliquez sur "Créer une checklist vide"

### Synchronisation échoue

**Symptôme :** Erreur lors de la synchronisation SharePoint

**Solutions :**
1. Vérifier la connexion Internet
2. Vérifier les identifiants Azure AD dans Réglages
3. Vérifier que le site SharePoint est accessible
4. Désactiver et réactiver la synchronisation automatique
5. Se déconnecter et se reconnecter à Azure AD

### Données perdues

**Symptôme :** Les conducteurs ou les données ont disparu

**Solutions :**
1. Vérifier que vous êtes connecté avec le bon compte Azure AD
2. Vérifier le filtre par Manager Traction (`ownerSNCFId`)
3. Vérifier dans SharePoint que les données existent toujours
4. Importer depuis un export JSON si vous en avez un

### Export ne fonctionne pas

**Symptôme :** Impossible d'exporter les données

**Solutions :**
1. Vérifier qu'il y a des données à exporter
2. Vérifier les permissions de l'app Fichiers
3. Essayer d'exporter vers un autre emplacement (AirDrop, Email, etc.)

---

## 📚 Ressources et Documentation

### Guides Disponibles

- **Guide de démarrage rapide** : `Documentation/QUICK_START_GUIDE.md`
- **Configuration SharePoint** : `Documentation/GUIDE_CONFIG_SHAREPOINT.md`
- **Mode démonstration** : `Documentation/MODE_DEMO_REVIEW.md`
- **Architecture** : `Documentation/ARCHITECTURE_SUMMARY.md`

### Structure des Données

Les données sont organisées comme suit :

**Localement (UserDefaults) :**
- Liste des conducteurs
- Checklist triennale
- Checklist VP
- Checklist TE
- Préférences de synchronisation

**Sur SharePoint (si activé) :**
```
RailSkills/
├── CTT_{cttId}/          # Dossier par Manager Traction (CTT_ est un préfixe technique)
│   └── Data/
│       └── {nom-conducteur}/
│           ├── {nom-conducteur}.json
│           └── {nom-conducteur}_backup.json
└── Checklists/
    ├── questions_CFL.json      # Checklist triennale
    ├── questions_VP.json       # Checklist VP
    └── questions_TE.json       # Checklist TE
```

---

## 🔒 Sécurité et Confidentialité

### Protection des Données

- Les données sont stockées localement sur votre appareil
- Les exports peuvent être chiffrés avec AES-GCM
- La synchronisation SharePoint utilise OAuth 2.0 (Azure AD)
- Aucun tracking ni collecte de données publicitaires

### Isolation des Données

- Chaque Manager Traction ne peut accéder qu'à ses propres données
- Validation de l'identité lors de la synchronisation
- Pas d'accès croisé entre différents Manager Traction

Pour plus d'informations, consultez la [Politique de Confidentialité](PRIVACY_POLICY_TEMPLATE.md).

---

## 🆘 Signaler un Problème

Pour signaler un bug ou demander de l'aide :

1. **Collecter les informations suivantes :**
   - Version de l'application (visible dans Réglages)
   - Version d'iOS/iPadOS
   - Modèle de l'appareil
   - Description détaillée du problème
   - Étapes pour reproduire le problème (si applicable)
   - Captures d'écran (si applicable)

2. **Envoyer un email à :** RailSkills@syl20.org

3. **Sujet de l'email :** [RailSkills Support] Description du problème

---

## 📝 Notes de Version

### Version 1.2

- ✅ Ajout des onglets VP (Visite Périodique) et TE (Test d'Évaluation)
- ✅ Support de 3 checklists indépendantes (Triennale, VP, TE)
- ✅ Synchronisation SharePoint pour les checklists VP et TE
- ✅ Améliorations de l'interface utilisateur
- ✅ Corrections de bugs

### Versions Précédentes

Consultez les notes de version dans l'application (Réglages → À propos) ou dans `Documentation/NOTES_VERSION_TESTFLIGHT.md`.

---

## ✅ Checklist de Vérification

Avant de contacter le support, vérifiez :

- [ ] Version iOS/iPadOS 18.0 ou supérieure
- [ ] Application à jour (version 1.2+)
- [ ] Connexion Internet active (si utilisation SharePoint)
- [ ] Identifiants Azure AD corrects (si utilisation SharePoint)
- [ ] Permissions accordées (microphone, reconnaissance vocale si utilisées)
- [ ] Redémarrage de l'application effectué

---

## 🌐 Informations Légales

**Application :** RailSkills  
**Développeur :** Sylvain GALLON  
**Email :** RailSkills@syl20.org  
**Version :** 1.2+  
**Plateforme :** iOS 18+ / iPadOS 18+  
**Conformité :** RGPD, Loi Informatique et Libertés, Guidelines Apple App Store

---

**Dernière mise à jour :** 9 décembre 2025

