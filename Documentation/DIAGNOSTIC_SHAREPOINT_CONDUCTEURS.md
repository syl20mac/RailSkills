# 🔍 Diagnostic - Conducteurs non synchronisés sur SharePoint

## ❓ Problème rapporté

Les conducteurs présents sur l'iPad n'ont pas été synchronisés sur SharePoint.

## ✅ Conditions nécessaires pour la synchronisation automatique

Pour que les conducteurs se synchronisent automatiquement vers SharePoint, **3 conditions** doivent être remplies :

### 1. SharePoint doit être configuré ✓

```
Réglages → Synchronisation SharePoint → Configuration Azure AD
```

Vérifier que :
- ✅ **Client Secret** est configuré (stocké dans Keychain)
- ✅ **Test de connexion** réussit (bouton "Tester la connexion")
- ✅ Statut affiché : "✓ Configuré"

### 2. Synchronisation automatique activée ✓

```
Réglages → Synchronisation SharePoint
```

Vérifier que :
- ✅ **Toggle "Synchronisation automatique SharePoint"** est activé (par défaut OUI)

### 3. Il doit y avoir des conducteurs sur l'iPad ✓

```
Onglet Gestion → Liste des conducteurs
```

Vérifier que :
- ✅ Au moins un conducteur existe dans la liste

## 🔧 Diagnostic étape par étape

### Étape 1 : Vérifier la configuration SharePoint

1. Ouvrir **Réglages** (⚙️)
2. Section **Sécurité & Synchronisation**
3. Cliquer sur **Synchronisation SharePoint**
4. Vérifier :
   - État : "✓ Configuré" ou "⚠️ Non configuré"
   - Dernière synchronisation : Date affichée ou "Jamais"

**Si "Non configuré"** :
- Aller dans **Configuration Azure AD**
- Entrer le **Client Secret** fourni
- Cliquer sur **Tester la connexion**
- Si succès → Enregistrer

**Si "Configuré" mais pas de synchronisation** :
- Passer à l'étape 2

### Étape 2 : Vérifier la synchronisation automatique

Dans **Synchronisation SharePoint**, vérifier que :
- **Synchronisation automatique SharePoint** = ☑️ ACTIVÉ

**Si désactivé** :
- Activer le toggle
- Les conducteurs seront synchronisés automatiquement dans les 2 secondes

**Si activé** :
- Passer à l'étape 3

### Étape 3 : Vérifier la présence de conducteurs

1. Aller dans l'onglet **Gestion** (icône personnes)
2. Vérifier qu'il y a au moins 1 conducteur dans la liste

**Si aucun conducteur** :
- Ajouter un conducteur via le bouton **+**
- La synchronisation se déclenchera automatiquement

**Si des conducteurs existent** :
- Passer à l'étape 4

### Étape 4 : Forcer une synchronisation manuelle

Dans **Synchronisation SharePoint** :
1. Scroller vers le bas
2. Cliquer sur **"Synchroniser les conducteurs uniquement"**
3. Observer le message de résultat

**Messages possibles** :

✅ **"X conducteur(s) synchronisé(s)"** → Synchronisation réussie
- Vérifier sur SharePoint : `RailSkills/Data/{nom-conducteur}/{nom-conducteur}.json`

❌ **"Erreur : Non configuré"** → Retourner à l'étape 1

❌ **"Erreur : Connexion impossible"** → Problème réseau ou Azure AD
- Vérifier la connexion Internet
- Re-tester la connexion Azure AD
- Vérifier que le Client Secret est correct

❌ **"Erreur : Unauthorized"** → Problème d'authentification
- Le Client Secret est peut-être expiré ou incorrect
- Contacter l'administrateur Azure AD
- Récupérer un nouveau Client Secret

### Étape 5 : Vérifier sur SharePoint

1. Se connecter à SharePoint : `https://sncf.sharepoint.com/sites/railskillsgrpo365`
2. Aller dans **Documents**
3. Naviguer vers `RailSkills/Data/`
4. Vérifier la présence des dossiers conducteurs

**Structure attendue** :
```
RailSkills/
└── Data/
    ├── Jean_Dupont/
    │   ├── Jean_Dupont.json          # Fichier principal
    │   └── Jean_Dupont_1732460123.json  # Archive
    ├── Marie_Martin/
    │   ├── Marie_Martin.json
    │   └── Marie_Martin_1732460456.json
    └── ...
```

## 🐛 Problèmes courants et solutions

### Problème 1 : "Client Secret non trouvé"

**Cause** : Le Client Secret n'a pas été sauvegardé correctement dans la Keychain

**Solution** :
1. Réglages → Synchronisation SharePoint → Configuration Azure AD
2. Re-saisir le Client Secret
3. Enregistrer
4. Tester la connexion

### Problème 2 : "Unauthorized 401"

**Cause** : Le Client Secret est expiré ou incorrect

**Solution** :
1. Contacter l'administrateur Azure AD
2. Demander un nouveau Client Secret
3. Le configurer dans l'application
4. Re-tester

### Problème 3 : Synchronisation silencieuse échouée

**Cause** : Les erreurs de synchronisation automatique sont loggées mais n'interrompent pas l'utilisateur (par design)

**Solution** :
1. Forcer une synchronisation manuelle (Étape 4)
2. Observer le message d'erreur
3. Appliquer la solution correspondante

### Problème 4 : "Site not found"

**Cause** : L'URL du site SharePoint est incorrecte ou l'application n'a pas accès

**Solution** :
1. Vérifier l'URL dans `AzureADConfig.swift` : `https://sncf.sharepoint.com/sites/railskillsgrpo365`
2. Vérifier que l'application Azure AD a les permissions sur ce site
3. Contacter l'administrateur SharePoint

### Problème 5 : Synchronisation lente ou bloquée

**Cause** : Beaucoup de conducteurs à synchroniser

**Solution** :
1. Attendre quelques minutes (chaque conducteur est synchronisé individuellement)
2. Vérifier l'indicateur de synchronisation en cours
3. Ne pas fermer l'application pendant la synchronisation

## 🔄 Déclencher manuellement la synchronisation

### Méthode 1 : Via le bouton dédié

```
Réglages → Synchronisation SharePoint → "Synchroniser les conducteurs uniquement"
```

### Méthode 2 : Modifier un conducteur

La synchronisation automatique se déclenche après toute modification :
1. Ouvrir un conducteur
2. Modifier n'importe quelle information
3. Enregistrer
4. La synchronisation se déclenche automatiquement après 2 secondes

### Méthode 3 : Ajouter un nouveau conducteur

1. Onglet Gestion → Bouton **+**
2. Créer un nouveau conducteur
3. Enregistrer
4. La synchronisation se déclenche automatiquement

## 📊 Vérifier l'état de la synchronisation

### Dans l'application

**Indicateur de synchronisation** (coin supérieur droit de l'onglet principal) :
- 🟢 **Vert** : Synchronisation réussie
- 🟡 **Jaune** : Synchronisation en cours
- 🔴 **Rouge** : Erreur de synchronisation

**Détails dans Réglages** :
```
Réglages → Synchronisation SharePoint
```
- **Dernière synchronisation** : Date et heure
- **État** : Message de succès ou d'erreur

### Sur SharePoint

1. Connexion : `https://sncf.sharepoint.com/sites/railskillsgrpo365`
2. Documents → `RailSkills/Data/`
3. Vérifier :
   - Présence des dossiers conducteurs
   - Date de modification des fichiers
   - Contenu des fichiers JSON

## 🆘 Si rien ne fonctionne

### Actions de dernier recours

1. **Redémarrer l'application** :
   - Fermer complètement RailSkills
   - Relancer
   - Essayer une synchronisation manuelle

2. **Vérifier les logs** :
   - Les logs sont affichés dans la console Xcode (si en développement)
   - Rechercher "SharePointSync" dans les logs

3. **Réinitialiser la configuration SharePoint** :
   - Réglages → Synchronisation SharePoint → Configuration Azure AD
   - Supprimer le Client Secret (si option disponible)
   - Re-configurer depuis zéro

4. **Vérifier les permissions Azure AD** :
   - L'application doit avoir les permissions :
     - `Sites.ReadWrite.All`
     - `Files.ReadWrite.All`
   - Contacter l'administrateur Azure AD pour vérifier

5. **Contacter le support** :
   - Fournir les informations suivantes :
     - Version de l'application
     - Nombre de conducteurs
     - Message d'erreur exact
     - Dernière synchronisation réussie (si applicable)

## 📝 Checklist de vérification rapide

- [ ] Client Secret configuré dans Azure AD
- [ ] Test de connexion réussi
- [ ] Synchronisation automatique activée
- [ ] Au moins 1 conducteur présent
- [ ] Connexion Internet active
- [ ] Synchronisation manuelle testée
- [ ] Vérifié sur SharePoint

## 🔐 Note de sécurité

Le Client Secret est stocké de manière sécurisée dans la **Keychain iOS**. Si vous changez de client secret :
1. Les anciennes synchronisations restent valides
2. Les nouvelles synchronisations utilisent le nouveau secret
3. Aucune perte de données

---

**Date :** 24 novembre 2024  
**Version :** RailSkills v2.0+  
**Support :** Documentation technique



