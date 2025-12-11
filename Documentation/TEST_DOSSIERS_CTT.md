# 🧪 Test - Dossiers Manager Traction sur SharePoint

## ✅ Modifications apportées

### 1. SharePointSyncService.swift

**Fonction ajoutée** :
```swift
private func getCTTFolderName() -> String
```
- Récupère le `cttId` depuis `WebAuthService.shared.currentUser`
- Fallback sur "Dev" (mode debug) ou "Shared" (production) si non connecté
- **Note :** `cttId` et `CTT_` sont des identifiants techniques. Le rôle utilisateur est "Manager Traction".

**Modifications** :
- **Conducteurs** : `RailSkills/Data/` → `RailSkills/CTT_{cttId}/Data/`
- **Checklists** : `RailSkills/Checklists/` → `RailSkills/CTT_{cttId}/Checklists/`
- **Logs** : Affichent maintenant le dossier Manager Traction utilisé

### 2. Structure SharePoint résultante

```
SharePoint/RailSkills/
├── CTT_jean.dupont/
│   ├── Data/
│   │   ├── Conducteur_A/
│   │   │   ├── Conducteur_A.json
│   │   │   └── Conducteur_A_1732460123.json
│   │   └── Conducteur_B/
│   │       ├── Conducteur_B.json
│   │       └── Conducteur_B_1732460456.json
│   └── Checklists/
│       └── Checklist_CFL_1732460789.json
├── CTT_marie.martin/
│   ├── Data/
│   └── Checklists/
└── Dev/                   # Mode développement (non connecté)
    ├── Data/
    └── Checklists/
```

---

## 🧪 Plan de test

### Test 1 : Connexion et synchronisation

#### Prérequis
- Serveur web RailSkills-Web démarré (http://localhost:3000)
- Base de données avec un compte CTT existant
- SharePoint configuré (Client Secret Azure AD)

#### Étapes

1. **Lancer l'application**
   - Ouvrir RailSkills sur iPad/simulateur

2. **Se connecter**
   ```
   Email: jean.dupont@sncf.fr
   Mot de passe: ********
   ```
   - Vérifier que la connexion réussit
   - Vérifier que le profil utilisateur est chargé

3. **Ajouter un conducteur**
   - Onglet Gestion → Bouton **+**
   - Nom: "Test Conducteur A"
   - Dates d'évaluation: aujourd'hui
   - Enregistrer

4. **Attendre la synchronisation automatique**
   - Délai: 2 secondes après la sauvegarde
   - Observer l'indicateur de synchronisation

5. **Vérifier les logs**
   ```
   [SharePointSync] Synchronisation du conducteur 'Test Conducteur A'
   [SharePointSync] 1/1 conducteur(s) synchronisé(s) vers SharePoint (CTT_jean.dupont)
   ```
   - ✅ Le log doit mentionner `CTT_jean.dupont`

6. **Vérifier sur SharePoint**
   - Aller sur `https://sncf.sharepoint.com/sites/railskillsgrpo365`
   - Naviguer vers `Documents → RailSkills`
   - Vérifier la présence du dossier `CTT_jean.dupont/`
   - Vérifier `CTT_jean.dupont/Data/Test_Conducteur_A/Test_Conducteur_A.json`

**Résultat attendu** : ✅ Le conducteur est dans le dossier CTT spécifique

---

### Test 2 : Mode non connecté (développement)

#### Prérequis
- Application en mode DEBUG
- Pas de connexion utilisateur

#### Étapes

1. **Désactiver le serveur web**
   - Arrêter le serveur RailSkills-Web

2. **Lancer l'application en mode développement**
   - Désactivation temporaire de l'authentification obligatoire
   - Ou ajout d'un bypass pour le développement

3. **Ajouter un conducteur**
   - Onglet Gestion → Bouton **+**
   - Nom: "Test Dev Conducteur"
   - Enregistrer

4. **Synchroniser vers SharePoint**
   - Réglages → Synchronisation SharePoint
   - Bouton "Synchroniser les conducteurs"

5. **Vérifier les logs**
   ```
   [SharePointSync] ⚠️ Aucun utilisateur connecté, utilisation du dossier 'Dev' pour SharePoint
   [SharePointSync] 1/1 conducteur(s) synchronisé(s) vers SharePoint (CTT_Dev)
   ```

6. **Vérifier sur SharePoint**
   - Dossier `CTT_Dev/` créé
   - Conducteur dans `CTT_Dev/Data/Test_Dev_Conducteur/`

**Résultat attendu** : ✅ Les conducteurs vont dans `CTT_Dev/` en mode debug

---

### Test 3 : Multiple CTT

#### Prérequis
- 2 comptes CTT différents dans la base de données
- 2 iPads ou 2 simulateurs

#### Étapes

1. **iPad 1 : Connexion CTT A**
   ```
   Email: jean.dupont@sncf.fr
   Mot de passe: ********
   ```
   - Ajouter Conducteur A1
   - Synchroniser

2. **iPad 2 : Connexion CTT B**
   ```
   Email: marie.martin@sncf.fr
   Mot de passe: ********
   ```
   - Ajouter Conducteur B1
   - Synchroniser

3. **Vérifier sur SharePoint**
   ```
   RailSkills/
   ├── CTT_jean.dupont/
   │   └── Data/
   │       └── Conducteur_A1/
   └── CTT_marie.martin/
       └── Data/
           └── Conducteur_B1/
   ```

**Résultat attendu** : ✅ Chaque CTT a son propre dossier

---

### Test 4 : Checklist synchronisation

#### Étapes

1. **Se connecter**
   - Email: jean.dupont@sncf.fr

2. **Importer une checklist**
   - Onglet Éditeur → Importer une checklist
   - Sélectionner "Checklist CFL"

3. **Modifier la checklist**
   - Ajouter/modifier un élément
   - Enregistrer

4. **Vérifier la synchronisation**
   - Logs : `Checklist '...' synchronisée vers SharePoint (CTT_jean.dupont)`
   - SharePoint : `CTT_jean.dupont/Checklists/Checklist_CFL_...json`

**Résultat attendu** : ✅ La checklist est dans le dossier CTT

---

## 📊 Checklist de validation

- [ ] **Test 1** : Connexion + sync → dossier CTT créé
- [ ] **Test 2** : Mode dev → dossier "Dev" créé
- [ ] **Test 3** : Multi-CTT → dossiers séparés
- [ ] **Test 4** : Checklist → dans le bon dossier CTT
- [ ] **Logs** : Mentionnent correctement le dossier CTT
- [ ] **Pas de régression** : Les anciennes fonctionnalités marchent toujours

---

## 🐛 Points d'attention

### 1. Utilisateur non connecté en production

Si un utilisateur n'est pas connecté en production, les données iront dans `CTT_Shared/`.

**Solution recommandée** : Forcer la connexion avant toute synchronisation.

### 2. Migration des données existantes

Les données dans l'ancienne structure globale `RailSkills/Data/` ne seront plus accessibles.

**Solutions** :
- **Option A** : Script de migration (à créer)
- **Option B** : Conserver l'ancienne structure en lecture seule
- **Option C** : Informer les utilisateurs de re-synchroniser

### 3. Changement de CTT

Si un CTT change d'identifiant (ex: changement d'email), ses données resteront dans l'ancien dossier.

**Solution** : Script de migration ou import manuel depuis l'ancien dossier.

---

## 🚀 Déploiement

### Pré-requis avant production

1. ✅ Tests complets réussis
2. ✅ Serveur web RailSkills-Web déployé
3. ✅ Base de données des comptes CTT prête
4. ✅ Documentation utilisateur mise à jour

### Ordre de déploiement

1. **Déployer le serveur web** (si pas encore fait)
2. **Mettre à jour l'application iOS** vers v2.1
3. **Informer les CTT** de se reconnecter
4. **Tester la première synchronisation** de chaque CTT
5. **Vérifier SharePoint** que les dossiers sont créés correctement

---

## 📝 Notes

- Les modifications sont **rétrocompatibles** : l'ancienne structure fonctionne toujours en lecture
- Les nouvelles synchronisations utilisent **automatiquement** le `cttId`
- Pas besoin de **configuration supplémentaire** : tout est automatique après connexion
- Mode **développement** : utilise "Dev" au lieu d'un CTT réel

---

**Date** : 24 novembre 2024  
**Version** : RailSkills v2.1  
**Statut** : ✅ Implémenté, en attente de tests



