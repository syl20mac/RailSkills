# Guide d'intégration du SDK SNCF_ID *(obsolète dans la version actuelle)*

> **Statut (RailSkills v2.0+)**  
> L’intégration SNCF_ID décrite ci-dessous **n’est plus utilisée** dans l’application.  
> L’app fonctionne désormais **sans authentification SNCF_ID**, avec des données partagées localement et une synchronisation SharePoint basée uniquement sur **Azure AD**.  
> Ce document est conservé **à titre d’archive technique** pour une éventuelle réintégration future.

## Vue d'ensemble

Ce guide détaille l'intégration complète du SDK SNCF_ID dans l'application RailSkills pour l'authentification automatique des CTT.

## Prérequis

- Xcode 14.3+
- iOS 12.0+ (minimum requis par le SDK)
- Accès au dépôt GitLab SNCF pour le SDK

## Étape 1 : Installation du SDK

### Option A : Via Swift Package Manager (Recommandé)

1. Dans Xcode, ouvrez le menu **File > Add Package Dependencies...**

2. Collez l'URL du dépôt :
   ```
   https://gitlab-repo-gpf.apps.eul.sncf.fr/dosn/groupemobileapp-dosn/90436/SNCFID-iOS-SwiftSources
   ```

3. Sélectionnez la version désirée (minimum 2.1.1)

4. Ajoutez le package à la target "RailSkills"

### Option B : Via CocoaPods

1. Créer un fichier `Podfile` à la racine du projet :
   ```ruby
   source 'https://gitlab-repo-gpf.apps.eul.sncf.fr/dosn/cem/SDK-SNCF-Pod-Specs-Repo.git'
   source 'https://github.com/CocoaPods/Specs.git'
   use_frameworks!

   target 'RailSkills' do
       pod 'SNCFID'
   end

   post_install do |installer| 
       installer.generated_projects.each do |project| 
           project.targets.each do |target| 
               target.build_configurations.each do |config| 
                   config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0' 
               end 
           end 
       end 
   end
   ```

2. Dans un terminal, exécutez :
   ```bash
   pod install
   ```

3. **Important** : Utilisez le fichier `.xcworkspace` généré, pas le `.xcodeproj`

## Étape 2 : Configuration du SDK

### 2.1. Ajouter les frameworks requis

Dans les **Build Settings** de votre projet, assurez-vous que les frameworks suivants sont liés :

- `SystemConfiguration.framework`
- `MessageUI.framework`
- `WebKit.framework`
- `SafariServices.framework`

### 2.2. Configuration du Info.plist

Ajoutez la configuration des URLs de redirection dans `Info.plist` :

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Viewer</string>
        <key>CFBundleURLIconFile</key>
        <string>Icon</string>
        <key>CFBundleURLName</key>
        <string>com.railskills.app</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>railskills</string>
        </array>
    </dict>
</array>
```

**Remplacez** :
- `com.railskills.app` par votre bundle identifier
- `railskills` par le protocole de votre URL de redirection (par exemple, si votre URL est `railskills://sncfid`, utilisez `railskills`)

### 2.3. Configuration pour le développement (optionnel)

⚠️ **Important** : Ne pas utiliser en production

Pour le développement uniquement, ajoutez dans `Info.plist` :

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Étape 3 : Initialisation du SDK

### 3.1. Mode Sandbox (pour les tests)

Dans `RailSkillsApp.swift`, ajoutez l'initialisation en mode sandbox :

```swift
import SNCFID

@main
struct RailSkillsApp: App {
    @StateObject private var toastManager = ToastNotificationManager()
    
    init() {
        // Activation des logs de debug (uniquement en développement)
        #if DEBUG
        SNCFIDLog.setTraceLevel(.debug)
        #else
        SNCFIDLog.setTraceLevel(.error)
        #endif
        
        // Définition des scopes à utiliser
        let scopes: [SNCFIDScope] = [.profile, .email, .department]
        
        // Initialisation en mode sandbox pour les tests
        #if DEBUG
        SNCFIDService.initSandbox(
            withRedirectUrl: .uri1,
            scopes: scopes,
            environment: .development
        )
        #endif
    }
    
    // ... reste du code
}
```

### 3.2. Mode Production

Une fois les identifiants obtenus du service OpenAM, remplacez l'initialisation sandbox par :

```swift
// Initialisation en mode production
let scopes: [SNCFIDScope] = [.profile, .email, .department]

SNCFIDService.initServiceWith(
    withClientId: "VOTRE_CLIENT_ID",
    clientSecret: "VOTRE_CLIENT_SECRET",
    redirectUrl: URL(string: "railskills://sncfid")!,
    scopes: scopes,
    environment: .production
)
```

## Étape 4 : Intégration dans RailSkillsApp

### 4.1. Gestion des URLs de redirection

Dans `RailSkillsApp.swift`, ajoutez la gestion des URLs de redirection :

```swift
import SwiftUI

@main
struct RailSkillsApp: App {
    @StateObject private var toastManager = ToastNotificationManager()
    
    // Gestionnaire d'URL pour SNCF_ID
    @State private var urlHandler: URLHandler?
    
    init() {
        // ... initialisation du SDK (voir étape 3)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(toastManager)
                .toastNotifications(manager: toastManager)
                .onOpenURL { url in
                    handleOpenURL(url)
                }
        }
    }
    
    /// Gère l'ouverture d'URL (pour SNCF_ID)
    private func handleOpenURL(_ url: URL) {
        SNCFIDService.sharedInstance?.processRedirectUrl(
            url,
            success: {
                Logger.success("Authentification SNCF_ID réussie via URL", category: "SNCFID")
                // La notification SNCFIDNotificationUserAuthenticated sera envoyée
            },
            failure: { error in
                Logger.error("Erreur lors du traitement de l'URL SNCF_ID: \(error?.localizedDescription ?? "Inconnue")", category: "SNCFID")
                error?.log()
            }
        )
    }
}
```

### 4.2. Utiliser l'implémentation réelle du SDK

Dans `SNCFIdentityService.swift`, modifiez l'initialisation pour utiliser `SNCFIDSessionManagerImpl` :

```swift
@MainActor
class SNCFIdentityService: ObservableObject {
    static let shared = SNCFIdentityService()
    
    /// Gestionnaire de session SNCF_ID (utilise l'implémentation réelle du SDK)
    var sessionManager: SNCFIDSessionManager = SNCFIDSessionManagerImpl() // Remplacer DefaultSNCFIDSessionManager
    
    // ... reste du code
}
```

### 4.3. Activer le SDK dans SNCFIDSessionManagerImpl

Dans `SNCFIDSessionManagerImpl.swift`, décommentez toutes les lignes marquées avec `// TODO:` :

1. Décommentez `import SNCFID` en haut du fichier
2. Décommentez toutes les méthodes qui utilisent `SNCFIDService.sharedInstance`
3. Implémentez la méthode `getCurrentSessionFromSDK()` pour récupérer les informations de l'utilisateur

## Étape 5 : Configuration des notifications

Les notifications SNCF_ID sont déjà configurées dans `SNCFIDSessionManagerImpl.swift`. Vérifiez que les noms de notifications correspondent :

```swift
Notification.Name("SNCFIDNotificationUserAuthenticated")
Notification.Name("SNCFIDNotificationUserDisconnected")
Notification.Name("SNCFIDNotificationUserAuthenticationError")
Notification.Name("SNCFIDNotificationUserCancelAuthentification")
```

## Étape 6 : Mise à jour de l'interface utilisateur

L'interface utilisateur (`CTTProfileView`) est déjà configurée pour utiliser le SDK. Le bouton "S'authentifier avec SNCF_ID" apparaîtra automatiquement si le SDK est disponible.

## Étape 7 : Tests

### Test en mode Sandbox

1. Compilez et lancez l'application
2. Allez dans **Réglages > Profil CTT**
3. Cliquez sur **"S'authentifier avec SNCF_ID"**
4. Vérifiez que le flux d'authentification se lance
5. Après authentification, vérifiez que votre identité est automatiquement configurée

### Vérification des logs

Activez les logs de debug pour voir les détails :

```swift
SNCFIDLog.setTraceLevel(.verbose) // Uniquement en développement
```

## Dépannage

### Le bouton d'authentification n'apparaît pas

- Vérifiez que le SDK est bien ajouté au projet
- Vérifiez que `SNCFIDSessionManagerImpl` est utilisé (pas `DefaultSNCFIDSessionManager`)
- Vérifiez que `isSDKAvailable` retourne `true`

### Erreur lors de l'authentification

- Vérifiez la configuration du `Info.plist` (URLs de redirection)
- Vérifiez que les identifiants (Client ID, Client Secret) sont corrects
- Vérifiez les logs avec `SNCFIDLog.setTraceLevel(.verbose)`

### L'URL de redirection ne fonctionne pas

- Vérifiez que le schéma d'URL dans `Info.plist` correspond à celui configuré dans OpenAM
- Vérifiez que la méthode `handleOpenURL` est bien appelée dans `RailSkillsApp`

## Migration des données existantes

Si des utilisateurs ont déjà configuré leur identité manuellement :

- L'identité manuelle est conservée
- Si l'utilisateur s'authentifie via SDK, l'identité SDK remplace l'identité manuelle
- Les données existantes (conducteurs, checklists) restent associées à l'identité précédente
- Les nouvelles données utiliseront la nouvelle identité

## Ressources

- Documentation officielle du SDK SNCF_ID
- Support technique SNCF
- Exemples de code fournis avec le SDK

## Notes importantes

⚠️ **Important** : 
- Ne pas inclure `NSAllowsArbitraryLoads` en production
- Utiliser le niveau de log `.error` ou `.debug` en production, jamais `.verbose`
- Vérifier que les identifiants (Client ID, Client Secret) sont sécurisés et ne sont pas commités dans le dépôt Git

