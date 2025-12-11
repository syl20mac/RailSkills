# Configuration Azure AD pour SharePoint

## 📋 Instructions de configuration

### Option 1 : Intégration dans l'application (Recommandé) ✅

Pour que **tous les utilisateurs** utilisent automatiquement le Client Secret **sans avoir à le saisir** :

1. **Ouvrez le fichier** `Configs/AzureADConfig.swift`

2. **Remplacez** cette ligne :
   ```swift
   static let clientSecret: String? = nil
   ```
   
   **Par** :
   ```swift
   static let clientSecret: String? = "VOTRE_CLIENT_SECRET_ICI"
   ```

3. **Sauvegardez** le fichier

4. **Vérifiez que le template n'est pas compilé** :
   - Dans Xcode, sélectionnez `AzureADConfig.template.txt` (ou `.swift` s'il existe encore)
   - Ouvrez le **File Inspector** (panneau de droite, ⌥⌘1)
   - Dans **Target Membership**, décochez votre cible d'app
   - ⚠️ Seul `AzureADConfig.swift` doit être coché dans le Target Membership

5. **Nettoyez le build** : Product > Clean Build Folder (⇧⌘K)

6. **Compilez** l'application

✅ **Résultat** : Tous les utilisateurs de l'application auront automatiquement accès à SharePoint sans avoir à saisir le Client Secret !

### Option 2 : Saisie manuelle (Alternative)

Si vous ne souhaitez pas intégrer le Client Secret dans l'application :

1. Laissez `AzureADConfig.swift` avec `clientSecret = nil`
2. Les utilisateurs pourront saisir le Client Secret dans l'application via :
   - **Réglages** → **Sécurité & Synchronisation** → **Configuration Azure AD** → **Configurer le Client Secret manuellement**

## 🔒 Sécurité

- ✅ Le fichier `AzureADConfig.swift` est **exclu de Git** (via `.gitignore`)
- ✅ Le Client Secret ne sera **jamais versionné** dans le dépôt
- ✅ Chaque développeur doit créer son propre fichier `AzureADConfig.swift` à partir du template

## 📝 Fichiers

- **`Documentation/AzureADConfig.template.txt`** : Template versionné dans Git (sans secret, fichier texte)
- **`Configs/AzureADConfig.swift`** : Configuration réelle (non versionnée, à créer manuellement)
- **`.gitignore`** : Exclut `AzureADConfig.swift` du dépôt Git

## ⚠️ Important

- **Ne versionnez JAMAIS** `AzureADConfig.swift` dans Git
- Le fichier `.gitignore` empêche déjà cela
- Chaque développeur qui clone le projet doit :
  1. Voir le template dans `Documentation/AzureADConfig.template.txt`
  2. Créer `Configs/AzureADConfig.swift` en s'inspirant du template
  3. Remplir le Client Secret dans `AzureADConfig.swift`
  4. Compiler l'application

## 🔄 Priorité de chargement

L'application charge le Client Secret dans cet ordre :

1. **Configuration intégrée** (`AzureADConfig.clientSecret`) - **Prioritaire**
2. **Keychain** (saisie manuelle par l'utilisateur) - **Fallback**

Si le Client Secret est intégré, les utilisateurs n'ont rien à faire !

