# 🔧 Solution à l'Erreur Réseau

## ⚠️ Problème

L'application affiche l'erreur : **"Erreur réseau: Connexion au serveur impossible"** lors de la tentative de connexion.

## 🔍 Causes possibles

1. **Le serveur web n'est pas démarré** : L'application essaie de se connecter à `http://localhost:3000/api` en mode DEBUG
2. **L'URL du serveur est incorrecte** : L'URL configurée n'est pas accessible
3. **Problème de connexion Internet** : Pas de connexion réseau active
4. **Le serveur n'est pas encore déployé** : L'application web RailSkills-Web n'est pas hébergée

## ✅ Solutions

### Solution 1 : Démarrer le serveur web (Mode Développement)

Si vous développez l'application web localement :

1. **Ouvrir un terminal** dans le dossier du projet web RailSkills-Web
2. **Démarrer le serveur** :
   ```bash
   npm start
   # ou
   node server.js
   ```
3. **Vérifier que le serveur écoute sur le port 3000** :
   - Le serveur doit être accessible à `http://localhost:3000`
   - L'API doit être accessible à `http://localhost:3000/api`

### Solution 2 : Configurer l'URL du serveur

Si le serveur est hébergé ailleurs :

1. **Dans l'application iOS** :
   - Aller dans **Paramètres** → **Configuration API web**
   - Entrer l'URL complète du serveur (ex: `https://railskills.syl20.org/api`)
   - Enregistrer la configuration

2. **Ou modifier directement dans le code** :
   - Ouvrir `Services/WebAuthService.swift`
   - Modifier la ligne 30 :
   ```swift
   return "https://votre-serveur.com/api"
   ```

### Solution 3 : Mode Hors Ligne (Développement)

Pour tester l'application sans serveur, vous pouvez :

1. **Désactiver temporairement l'authentification** :
   - Commenter les appels à `authService.login()` dans `LoginView.swift`
   - Permettre l'accès direct à l'application

2. **Utiliser des données mockées** :
   - Créer un utilisateur fictif pour les tests
   - Bypasser l'authentification en mode DEBUG

### Solution 4 : Vérifier la connexion réseau

1. **Vérifier la connexion Internet** :
   - Assurez-vous que l'iPad/iPhone a une connexion active
   - Testez avec Safari pour vérifier l'accès Internet

2. **Vérifier les paramètres réseau** :
   - Vérifiez que le firewall ne bloque pas les connexions
   - Vérifiez les paramètres VPN si applicable

## 📝 Améliorations apportées

J'ai amélioré la gestion des erreurs réseau dans `WebAuthService.swift` :

- ✅ Messages d'erreur plus explicites selon le type d'erreur
- ✅ Détection spécifique des erreurs de connexion (`URLError`)
- ✅ Messages adaptés pour :
  - Pas de connexion Internet
  - Serveur inaccessible
  - Délai d'attente dépassé
  - Autres erreurs réseau

## 🚀 Prochaines étapes

1. **Si vous développez** : Démarrez le serveur web local
2. **Si vous testez** : Configurez l'URL du serveur de production
3. **Si le serveur n'existe pas encore** : Utilisez le mode hors ligne pour tester l'application

## 📞 Support

Si le problème persiste :
- Vérifiez les logs dans la console Xcode
- Vérifiez que le serveur répond aux requêtes HTTP
- Testez l'URL avec un navigateur ou Postman

---

**Date :** 24 novembre 2024  
**Version :** RailSkills v2.1




