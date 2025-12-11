# Intégration du SDK SNCF_ID *(obsolète dans la version actuelle)*

> **Statut (RailSkills v2.0+)**  
> L’application ne s’appuie plus sur SNCF_ID pour isoler les données par CTT.  
> Les mécanismes décrits ci-dessous ne sont **pas activés** dans la version actuelle et ce document sert uniquement de **référence historique** si une réintégration du SDK est décidée plus tard.

## Vue d'ensemble

Ce document explique comment intégrer le SDK SNCF_ID dans l'application RailSkills pour l'authentification automatique des CTT (Cadres Transport Traction).

## Architecture

L'application utilise une architecture d'abstraction qui permet d'intégrer le SDK SNCF_ID tout en conservant un fallback vers la saisie manuelle si le SDK n'est pas disponible.

### Structure

1. **`SNCFIDSession.swift`** : Définit les protocoles et structures pour l'authentification SNCF_ID
   - `SNCFIDSession` : Représente une session authentifiée
   - `SNCFIDSessionManager` : Protocole à implémenter avec le SDK réel
   - `DefaultSNCFIDSessionManager` : Implémentation par défaut (fallback)

2. **`SNCFIdentityService.swift`** : Service principal gérant l'identité du CTT
   - Supporte l'authentification via SDK SNCF_ID
   - Fallback automatique vers la saisie manuelle si le SDK n'est pas disponible
   - Gère la persistance et la synchronisation de l'identité

## Étapes d'intégration

### 1. Ajouter le SDK SNCF_ID au projet

1. Téléchargez le SDK SNCF_ID fourni par SNCF
2. Ajoutez le framework `.framework` ou la bibliothèque au projet Xcode :
   - Glissez-déposez le fichier dans le projet
   - Cochez "Copy items if needed"
   - Sélectionnez la target "RailSkills"
   - Ajoutez-le à "Embedded Binaries" si nécessaire

3. Dans `Info.plist`, ajoutez les permissions nécessaires (selon la documentation du SDK)

### 2. Implémenter le gestionnaire de session SNCF_ID

Créez un nouveau fichier `SNCFIDSessionManagerImpl.swift` :

```swift
//
//  SNCFIDSessionManagerImpl.swift
//  RailSkills
//
//  Implémentation du gestionnaire de session SNCF_ID utilisant le SDK réel
//

import Foundation
// Importez le SDK SNCF_ID ici
// import SNCFIDSDK  // Exemple - remplacez par le nom réel du SDK

class SNCFIDSessionManagerImpl: SNCFIDSessionManager {
    // Propriétés pour le SDK SNCF_ID
    // private let sncfIDClient: SNCFIDClient?  // Exemple
    
    init() {
        // Initialiser le SDK SNCF_ID
        // self.sncfIDClient = SNCFIDClient.initialize(...)
    }
    
    var isSessionActive: Bool {
        // TODO: Implémenter avec le SDK SNCF_ID réel
        // Exemple : return sncfIDClient?.isAuthenticated ?? false
        return false
    }
    
    var currentSession: SNCFIDSession? {
        // TODO: Implémenter avec le SDK SNCF_ID réel
        // Exemple :
        // guard let userInfo = sncfIDClient?.currentUser else { return nil }
        // return SNCFIDSession(
        //     sncfIdentity: userInfo.identity,
        //     displayName: userInfo.name,
        //     email: userInfo.email,
        //     accessToken: sncfIDClient?.accessToken,
        //     expiresAt: sncfIDClient?.tokenExpiryDate,
        //     additionalInfo: userInfo.metadata
        // )
        return nil
    }
    
    func authenticate(completion: @escaping (Result<SNCFIDSession, SNCFIDError>) -> Void) {
        // TODO: Implémenter avec le SDK SNCF_ID réel
        // Exemple :
        // sncfIDClient?.authenticate { result in
        //     switch result {
        //     case .success(let userInfo):
        //         let session = SNCFIDSession(
        //             sncfIdentity: userInfo.identity,
        //             displayName: userInfo.name,
        //             email: userInfo.email,
        //             accessToken: sncfIDClient?.accessToken,
        //             expiresAt: sncfIDClient?.tokenExpiryDate,
        //             additionalInfo: userInfo.metadata
        //         )
        //         completion(.success(session))
        //     case .failure(let error):
        //         completion(.failure(.authenticationFailed(error.localizedDescription)))
        //     }
        // }
        completion(.failure(.sdkNotAvailable))
    }
    
    func signOut() {
        // TODO: Implémenter avec le SDK SNCF_ID réel
        // sncfIDClient?.signOut()
    }
    
    func refreshSession(completion: @escaping (Result<SNCFIDSession, SNCFIDError>) -> Void) {
        // TODO: Implémenter avec le SDK SNCF_ID réel
        // sncfIDClient?.refreshToken { result in
        //     // Traiter le résultat similaire à authenticate
        // }
        completion(.failure(.sdkNotAvailable))
    }
}
```

### 3. Configurer SNCFIdentityService pour utiliser le SDK

Dans `RailSkillsApp.swift` ou lors de l'initialisation de l'application :

```swift
// Remplacer le gestionnaire par défaut par l'implémentation réelle
let sdkManager = SNCFIDSessionManagerImpl()
SNCFIdentityService.shared.sessionManager = sdkManager

// Optionnel : Vérifier si une session est déjà active au démarrage
if sdkManager.isSessionActive {
    // L'identité sera automatiquement mise à jour via checkSDKSession()
}
```

### 4. Mettre à jour l'interface utilisateur

Dans `CTTProfileView.swift`, ajoutez un bouton pour l'authentification SDK :

```swift
// Dans le body de CTTProfileView
if SNCFIdentityService.shared.isSDKAvailable {
    Button(action: {
        SNCFIdentityService.shared.authenticateWithSDK { result in
            switch result {
            case .success:
                toastManager.show("Authentification SNCF_ID réussie", type: .success)
            case .failure(let error):
                toastManager.show("Erreur d'authentification: \(error.localizedDescription)", type: .error)
            }
        }
    }) {
        HStack {
            Image(systemName: "person.badge.key.fill")
            Text("S'authentifier avec SNCF_ID")
        }
    }
}
```

## Flux d'authentification

### Avec SDK SNCF_ID disponible

1. L'utilisateur clique sur "S'authentifier avec SNCF_ID"
2. `SNCFIdentityService.authenticateWithSDK()` est appelé
3. Le SDK SNCF_ID lance le processus d'authentification (popup, navigation, etc.)
4. Si réussie, la session est créée et l'identité est automatiquement configurée
5. L'identité est persistée et utilisée pour isoler les données

### Sans SDK SNCF_ID (fallback)

1. L'utilisateur saisit manuellement son identifiant SNCF et son nom
2. `SNCFIdentityService.setIdentity()` est appelé
3. L'identité est persistée et utilisée normalement

## Vérifications et tests

### Vérifier que le SDK est intégré

1. Compilez le projet avec le SDK SNCF_ID
2. Vérifiez que `SNCFIDSessionManagerImpl` est utilisé dans `SNCFIdentityService.shared.sessionManager`
3. Vérifiez que `isSDKAvailable` retourne `true`

### Tester l'authentification

1. Lancez l'application
2. Allez dans Réglages → Profil CTT
3. Cliquez sur "S'authentifier avec SNCF_ID"
4. Vérifiez que le flux d'authentification du SDK se lance
5. Vérifiez que l'identité est automatiquement configurée après authentification

## Migration des données existantes

Si des utilisateurs ont déjà configuré leur identité manuellement :

- L'identité manuelle est conservée
- Si l'utilisateur s'authentifie via SDK, l'identité SDK remplace l'identité manuelle
- Les données existantes (conducteurs, checklists) restent associées à l'identité précédente
- Les nouvelles données utiliseront la nouvelle identité

## Support et documentation

Pour plus d'informations sur le SDK SNCF_ID :

- Consultez la documentation officielle du SDK SNCF_ID
- Contactez le support technique SNCF si nécessaire
- Vérifiez les exemples de code fournis avec le SDK

## Notes importantes

⚠️ **Important** : L'implémentation actuelle (`DefaultSNCFIDSessionManager`) retourne toujours `false` pour `isSessionActive` et déclenche une erreur lors de l'authentification. Ceci permet de forcer l'utilisation de la saisie manuelle jusqu'à ce que le SDK réel soit intégré.

✅ Une fois le SDK intégré, remplacez `DefaultSNCFIDSessionManager` par `SNCFIDSessionManagerImpl` dans l'initialisation de `SNCFIdentityService`.

