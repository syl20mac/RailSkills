# Mode Démonstration pour Reviewers Apple

## 📋 Contexte

Apple a rejeté l'application car les reviewers ne peuvent pas accéder à toutes les fonctionnalités sans authentification. Ce document explique comment utiliser le mode démonstration pour permettre aux reviewers d'Apple de tester l'application complètement.

## 🎯 Solution Implémentée

Un **mode démonstration** a été ajouté à l'application qui permet d'accéder à toutes les fonctionnalités sans authentification réelle.

## 🚀 Activation du Mode Démo

### Pour les Reviewers Apple

1. **Lancer l'application**
2. **Sur l'écran de connexion**, cliquer sur le bouton **"Mode démonstration"** (bouton vert en bas de l'écran)
3. Le mode démo s'active automatiquement et charge des données de démonstration

### Données de Démonstration Incluses

Le mode démo charge automatiquement :

- **3 conducteurs de démonstration** avec :
  - Dates de début triennale variées
  - Progression de checklist différente pour chaque conducteur
  - Données réalistes pour tester toutes les fonctionnalités

- **1 checklist de démonstration** avec :
  - 3 catégories (Sécurité, Technique, Réglementaire)
  - 9 questions au total
  - Structure complète pour tester le suivi

- **Profil utilisateur de démonstration** :
  - Email : `demo.reviewer@sncf.fr`
  - Nom : `Reviewer Apple`
  - Rôle : Administrateur (accès complet)

## ✅ Fonctionnalités Accessibles en Mode Démo

Toutes les fonctionnalités de l'application sont accessibles en mode démo :

- ✅ Suivi des conducteurs
- ✅ Checklist complète avec validation des questions
- ✅ Notes et dates de suivi
- ✅ Dashboard avec graphiques triennaux
- ✅ Export/Import de données
- ✅ Génération de rapports PDF
- ✅ Partage de données
- ✅ Synchronisation SharePoint (simulée)

## 🔧 Détails Techniques

### Services Créés

1. **DemoModeService** : Gère l'état du mode démo
2. **DemoDataService** : Crée et charge les données de démonstration
3. **Modifications dans WebAuthService** : Support du mode démo pour l'authentification

### Fichiers Modifiés

- `Services/DemoModeService.swift` (nouveau)
- `Services/DemoDataService.swift` (nouveau)
- `Services/WebAuthService.swift` (modifié)
- `Services/Store.swift` (modifié pour charger les données de démo)
- `Views/Auth/LoginView.swift` (ajout du bouton mode démo)

## 📝 Instructions pour App Store Connect

Dans la section **"Beta App Review Information"** de TestFlight, vous pouvez ajouter :

```
Mode démonstration disponible : 
Sur l'écran de connexion, cliquer sur le bouton "Mode démonstration" 
pour accéder à toutes les fonctionnalités avec des données de démonstration.
```

**OU** vous pouvez simplement mentionner dans les notes de review :

> "L'application dispose d'un mode démonstration accessible depuis l'écran de connexion. Cliquez sur le bouton 'Mode démonstration' pour accéder à toutes les fonctionnalités avec des données pré-chargées."

## 🔒 Sécurité

- Le mode démo est **désactivé par défaut** en production
- En mode DEBUG, le mode démo peut s'activer automatiquement si aucune authentification n'est présente
- Les données de démo sont **isolées** et ne se synchronisent pas avec les vraies données

## 🧪 Test du Mode Démo

Pour tester localement :

1. Lancer l'application
2. Sur l'écran de connexion, cliquer sur "Mode démonstration"
3. Vérifier que :
   - 3 conducteurs sont présents
   - La checklist est chargée
   - Toutes les fonctionnalités sont accessibles
   - Les graphiques triennaux s'affichent correctement

## 📞 Support

Si les reviewers rencontrent des problèmes, ils peuvent :
- Utiliser le mode démonstration
- Contacter le développeur via App Store Connect

---

**Note** : Le mode démo est conçu spécifiquement pour les reviewers Apple et permet de tester toutes les fonctionnalités sans configuration supplémentaire.
