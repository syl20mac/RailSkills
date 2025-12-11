# 🔐 Secret Organisationnel - Guide Complet

## 📋 Qu'est-ce que le Secret Organisationnel ?

Le **secret organisationnel** est un code secret partagé entre tous les appareils de votre organisation (CTT/ARC) qui permet de :
- ✅ **Chiffrer** les fichiers d'export de conducteurs
- ✅ **Déchiffrer** les fichiers importés depuis d'autres appareils
- ✅ **Garantir la confidentialité** des données partagées

## 🔒 Sécurité Améliorée

**Nouvelle version (v2.1)** : Le secret organisationnel est maintenant stocké dans la **Keychain iOS** au lieu de UserDefaults, offrant une sécurité renforcée :

- ✅ **Stockage sécurisé** : La Keychain est chiffrée par iOS
- ✅ **Protection contre l'accès** : Seule l'application peut accéder au secret
- ✅ **Migration automatique** : Les anciens secrets dans UserDefaults sont automatiquement migrés vers la Keychain

## 🎯 Fonctionnement

### 1. Secret par Défaut

Par défaut, l'application utilise le secret : `RailSkills.Default.2024`

- ✅ **Compatible** avec tous les fichiers existants
- ⚠️ **Moins sécurisé** (connu publiquement)
- 💡 **Idéal pour** : Tests et développement

### 2. Secret Personnalisé

Pour une sécurité renforcée, configurez un **secret unique** pour votre organisation :

- ✅ **Confidentialité maximale** : Seuls les appareils avec le même secret peuvent déchiffrer
- ✅ **Contrôle total** : Vous décidez qui peut accéder aux données
- 💡 **Idéal pour** : Production et données sensibles

## 📱 Configuration

### Méthode 1 : Depuis l'Application

1. Ouvrir **Réglages** → **Secret organisationnel**
2. Cliquer sur **"Configurer le secret"**
3. Saisir votre secret personnalisé
4. Enregistrer

### Méthode 2 : Partage via QR Code

**Pour partager le secret entre plusieurs appareils :**

1. **Sur l'appareil source** :
   - Réglages → Secret organisationnel
   - Cliquer sur **"Afficher le QR code du secret"**
   - Le QR code s'affiche avec le secret

2. **Sur l'appareil cible** :
   - Réglages → Secret organisationnel
   - Cliquer sur **"Scanner le QR code du secret"**
   - Scanner le QR code de l'appareil source
   - Le secret est automatiquement configuré

### Méthode 3 : Saisie Manuelle

Si vous connaissez le secret, vous pouvez le saisir manuellement dans les paramètres.

## 🔄 Migration Automatique

L'application migre automatiquement les secrets stockés dans l'ancien système (UserDefaults) vers la Keychain :

- ✅ **Transparent** : Aucune action requise
- ✅ **Sécurisé** : Les anciens secrets sont supprimés après migration
- ✅ **Rétrocompatible** : Les anciens fichiers continuent de fonctionner

## ⚙️ Utilisation Technique

### Dérivation de la Clé

Le secret organisationnel est transformé en clé de chiffrement via :

1. **Combinaison** : `secret + "ctt.RailSkills.encryption.salt"`
2. **Hachage SHA256** : Génère une clé de 256 bits
3. **Clé AES-GCM** : Utilisée pour chiffrer/déchiffrer les données

### Format de Chiffrement

Les fichiers chiffrés utilisent **AES-GCM** avec :
- **Nonce unique** : 12 bytes générés aléatoirement
- **Tag d'authentification** : 16 bytes pour vérifier l'intégrité
- **Métadonnées signées** (optionnel) : Version, date, checksum avec HMAC-SHA256

## ⚠️ Important

### Règles à Respecter

1. **Même secret partout** : Tous les appareils qui partagent des fichiers doivent avoir le **même secret**
2. **Secret fort** : Utilisez un secret d'au moins 16 caractères avec lettres, chiffres et symboles
3. **Ne pas partager publiquement** : Le secret doit rester confidentiel au sein de votre organisation
4. **Sauvegarde** : Notez le secret dans un endroit sûr (gestionnaire de mots de passe)

### Que se passe-t-il si les secrets ne correspondent pas ?

Si vous essayez d'importer un fichier chiffré avec un secret différent :
- ❌ **L'import échoue** avec un message d'erreur
- 🔍 **Message** : "Erreur lors du déchiffrement"
- 💡 **Solution** : Vérifiez que les deux appareils ont le même secret

## 🔧 Réinitialisation

Pour revenir au secret par défaut :

1. Réglages → Secret organisationnel
2. Cliquer sur **"Réinitialiser au secret par défaut"**
3. Confirmer

⚠️ **Attention** : Après réinitialisation, vous ne pourrez plus déchiffrer les fichiers créés avec l'ancien secret personnalisé.

## 📊 Vérification

Pour vérifier si un secret personnalisé est configuré :

- **Dans l'application** : Réglages → Secret organisationnel
  - Si "Par défaut" est affiché → Secret par défaut utilisé
  - Si "Secret configuré" est affiché → Secret personnalisé actif

## 🚀 Bonnes Pratiques

1. **Choisir un secret fort** :
   - Minimum 16 caractères
   - Mélange de lettres, chiffres, symboles
   - Exemple : `SNCF-RailSkills-2024-CTTLuxembourg!`

2. **Partager de manière sécurisée** :
   - Via QR code (recommandé)
   - En personne (oralement)
   - Via canal sécurisé (jamais par email non chiffré)

3. **Documenter** :
   - Notez le secret dans un gestionnaire de mots de passe
   - Partagez-le uniquement avec les CTT/ARC autorisés

4. **Rotation périodique** :
   - Changez le secret tous les 6-12 mois
   - Informez tous les utilisateurs avant le changement

## 🔍 Dépannage

### Problème : "Erreur lors du déchiffrement"

**Causes possibles** :
- Les deux appareils n'ont pas le même secret
- Le fichier a été corrompu
- Le secret a été modifié après l'export

**Solutions** :
1. Vérifier que les deux appareils ont le même secret
2. Réessayer l'export/import
3. Vérifier l'intégrité du fichier

### Problème : "Secret non trouvé"

**Causes possibles** :
- Le secret n'a pas été sauvegardé correctement
- Problème d'accès à la Keychain

**Solutions** :
1. Reconfigurer le secret
2. Redémarrer l'application
3. Vérifier les permissions de l'application

## 📝 Notes Techniques

- **Stockage** : Keychain iOS (`com.railskills.encryption`)
- **Algorithme** : AES-GCM 256 bits
- **Dérivation** : SHA256 avec salt fixe
- **Compatibilité** : iOS 16+

---

**Date :** 24 novembre 2024  
**Version :** RailSkills v2.1  
**Sécurité** : Keychain iOS (amélioration v2.1)




