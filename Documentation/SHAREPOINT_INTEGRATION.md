# Guide d'intégration SharePoint avec Azure AD

## 📋 Vue d'ensemble

L'application RailSkills intègre maintenant la synchronisation avec SharePoint via Azure AD Client Credential Flow. Cela permet de :
- Sauvegarder automatiquement les données dans SharePoint
- Centraliser les données pour toute l'organisation
- Réaliser des backups centralisés

## 🔧 Configuration requise

### 1. Informations Azure AD reçues

Vous avez reçu les informations suivantes :
- **Tenant ID** : `4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9`
- **App ID (Client ID)** : `bd394412-97bf-4513-a59f-e023b010dff7`
- **Client Secret** : Fourni dans un email séparé
- **Site SharePoint** : `https://sncf.sharepoint.com/sites/railskillsgrpo365`

### 2. Configuration dans l'application

#### Étape 1 : Configurer le Client Secret

1. Ouvrez l'application RailSkills
2. Allez dans l'onglet **Réglages**
3. Dans la section **Sécurité & Synchronisation**, cliquez sur **Synchronisation SharePoint**
4. Cliquez sur **Configuration Azure AD**
5. Entrez le **Client Secret** reçu par email
6. Cliquez sur **Enregistrer**
7. Testez la connexion avec le bouton **Tester la connexion Azure AD**

#### Étape 2 : Synchroniser les données

Une fois le Client Secret configuré :

1. Retournez dans **Synchronisation SharePoint**
2. Cliquez sur **Synchroniser tout vers SharePoint**
3. Les données seront uploadées dans SharePoint :
   - `RailSkills/Data/drivers_latest.json` (fichier des conducteurs)
   - `RailSkills/Checklists/[nom_checklist].json` (fichiers de checklists)

## 📁 Structure SharePoint

Les données sont organisées comme suit dans SharePoint :

```
RailSkills/
├── Data/
│   ├── drivers_latest.json          # Dernière version des conducteurs
│   └── drivers_[timestamp].json     # Archives horodatées
└── Checklists/
    └── [nom_checklist]_[timestamp].json  # Checklists archivées
```

## 🔒 Sécurité

- **Client Secret** : Stocké de manière sécurisée dans la Keychain iOS
- **Access Token** : Généré automatiquement avec expiration automatique
- **Renouvellement** : Les tokens sont renouvelés automatiquement

## 🔄 Synchronisation

### Synchronisation manuelle

La synchronisation est actuellement **manuelle** via l'interface :

- **Synchroniser tout** : Synchronise conducteurs + checklist
- **Synchroniser les conducteurs seulement** : Synchronise uniquement les conducteurs
- **Synchroniser la checklist seulement** : Synchronise uniquement la checklist

### Fréquence recommandée

- Après chaque modification importante
- À la fin de chaque journée de travail
- Avant de quitter l'application pour une période prolongée

## 📊 Fonctionnalités

### ✅ Implémenté

- Authentification Azure AD (Client Credential)
- Upload des conducteurs vers SharePoint
- Upload des checklists vers SharePoint
- Gestion sécurisée du Client Secret (Keychain)
- Création automatique des dossiers SharePoint
- Archivage avec timestamps
- Gestion des erreurs et feedback utilisateur

### 🔜 À venir (si nécessaire)

- Synchronisation automatique en arrière-plan
- Téléchargement depuis SharePoint
- Résolution de conflits
- Synchronisation incrémentale

## ⚠️ Notes importantes

1. **Client Secret** : Ne partagez jamais le Client Secret. Il doit rester confidentiel.
2. **Permissions SharePoint** : Assurez-vous que l'application Azure AD a les permissions nécessaires sur le site SharePoint.
3. **Connexion réseau** : La synchronisation nécessite une connexion Internet active.
4. **Erreurs** : En cas d'erreur, consultez les logs dans la console ou contactez le support.

## 🐛 Dépannage

### "Client Secret non configuré"
- Allez dans Réglages → Synchronisation SharePoint → Configuration Azure AD
- Entrez le Client Secret et testez la connexion

### "Site SharePoint introuvable"
- Vérifiez que l'application Azure AD a les permissions sur le site SharePoint
- Vérifiez que le site existe : `https://sncf.sharepoint.com/sites/railskillsgrpo365`

### "Erreur d'authentification"
- Vérifiez que le Client Secret est correct
- Vérifiez que le Tenant ID et App ID sont corrects dans le code (ils sont déjà configurés)

### "Erreur HTTP 403"
- Vérifiez les permissions de l'application Azure AD sur SharePoint
- Contactez l'administrateur SharePoint pour vérifier les permissions

## 📝 Logs

Les opérations de synchronisation sont loggées dans la console avec le préfixe :
- `AzureADService` : Pour les opérations d'authentification
- `SharePointSync` : Pour les opérations de synchronisation
- `SecretManager` : Pour la gestion du Client Secret

Pour voir les logs dans Xcode :
1. Ouvrez la console (⌘⇧C)
2. Filtrez par "RailSkills" ou le nom du service

