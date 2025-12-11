# 🔧 Retrait du Mode Développement

**Date :** 26 novembre 2025  
**Version :** RailSkills v2.0  
**Statut :** ✅ Complété

---

## 📋 Modifications effectuées

### 1. **Suppression du mode développement**

Le mode développement qui permettait de bypasser l'authentification a été **complètement retiré**.

**Fichiers concernés :**
- ✅ `RailSkillsApp.swift` - Plus de bypass d'authentification
- ✅ `LoginView.swift` - Plus de bouton "Mode développement (sans serveur)"
- ✅ `SettingsView.swift` - Plus de section "Développement"
- ✅ `MODE_DEVELOPPEMENT.md` - Documentation supprimée

---

### 2. **Configuration de l'URL du serveur backend**

**Problème identifié :**
L'application en mode DEBUG essayait de se connecter à `http://localhost:3000/api`, mais le serveur de production est déjà déployé sur `https://railskills.syl20.org`.

**Solution appliquée :**

```swift
// Services/WebAuthService.swift

/// URL de base de l'API web (configurable)
var baseURL: String {
    // Récupérer depuis UserDefaults ou utiliser la valeur par défaut
    if let savedURL = UserDefaults.standard.string(forKey: "web_api_base_url"), !savedURL.isEmpty {
        return savedURL
    }
    
    // Utiliser le serveur de production (railskills.syl20.org)
    return "https://railskills.syl20.org/api"
}
```

**Avant :**
- ❌ DEBUG : `http://localhost:3000/api` (serveur local inaccessible)
- ✅ RELEASE : `https://railskills.syl20.org/api`

**Après :**
- ✅ Toujours : `https://railskills.syl20.org/api`

---

## 🎯 Comportement actuel

### ✅ L'application affiche maintenant **obligatoirement** l'écran de connexion

1. **Au démarrage** → Écran de connexion
2. **L'utilisateur entre ses identifiants** (email + mot de passe)
3. **L'app se connecte à** → `https://railskills.syl20.org/api/auth/login`
4. **Après authentification réussie** → Accès à l'application

### 🔒 Sécurité renforcée

- ❌ Plus de bypass possible
- ✅ Authentification obligatoire pour tous les utilisateurs
- ✅ Connexion directe au serveur de production
- ✅ Token JWT sécurisé pour toutes les requêtes

---

## 🧪 Test de connexion

Pour vérifier que le serveur est accessible :

```bash
# Test 1 : Ping du serveur
ping railskills.syl20.org

# Test 2 : Vérifier l'API
curl https://railskills.syl20.org/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test"}'

# Réponse attendue (erreur normale si identifiants incorrects) :
# {"error": "Invalid credentials"} ✅
```

---

## 📱 Impact sur les utilisateurs

### Avant (avec mode développement)
- 👨‍💻 **Développeur** : Pouvait bypasser la connexion
- 👤 **Utilisateur final** : Devait se connecter normalement

### Après (sans mode développement)
- 👨‍💻 **Développeur** : Doit se connecter avec ses identifiants
- 👤 **Utilisateur final** : Aucun changement

---

## 🔐 Configuration requise

### Pour que l'authentification fonctionne

**1. Serveur backend démarré**
```bash
# Sur votre serveur (NAS Terramaster ou autre)
cd /chemin/vers/RailSkills-Web
npm start  # ou pm2 start server.js
```

**2. Certificat SSL valide**
- ✅ `https://railskills.syl20.org` doit avoir un certificat SSL valide
- ✅ Let's Encrypt ou certificat commercial

**3. Base de données accessible**
- ✅ PostgreSQL doit être démarré
- ✅ Les tables `users` et `ctts` doivent exister

**4. Compte utilisateur créé**
```bash
# Créer un compte depuis l'app iPad
# OU directement en base de données
```

---

## 🚀 Prochaines étapes

### Recommandations

1. **Créer des comptes de test**
   - CTT de test pour la validation
   - ARC de test pour les assistants

2. **Documenter les identifiants**
   - Créer un fichier `.env.local` (non versionné) avec les identifiants de test
   - Utiliser un gestionnaire de mots de passe (1Password, Bitwarden)

3. **Monitorer les connexions**
   - Vérifier les logs du serveur (`/api/auth/login`)
   - Détecter les tentatives d'authentification échouées

4. **Backup des données**
   - Sauvegarder régulièrement la base de données
   - Exporter les données critiques (conducteurs, checklists)

---

## 📝 Notes techniques

### URL personnalisable

L'URL du serveur peut être modifiée dynamiquement via `UserDefaults` :

```swift
// Pour changer l'URL sans recompiler l'app
UserDefaults.standard.set("https://autre-serveur.com/api", forKey: "web_api_base_url")
```

**Cas d'usage :**
- Environnement de staging/pré-production
- Serveur de backup
- Tests d'intégration

### Gestion des erreurs réseau

L'app affiche des messages d'erreur clairs :

| Code erreur | Message affiché | Action utilisateur |
|------------|-----------------|-------------------|
| **No internet** | "Aucune connexion Internet" | Vérifier Wi-Fi/4G |
| **Server unreachable** | "Serveur inaccessible" | Vérifier que le serveur est démarré |
| **Timeout** | "Délai d'attente dépassé" | Réessayer plus tard |
| **Invalid credentials** | "Email ou mot de passe incorrect" | Vérifier identifiants |
| **Server error (500)** | "Erreur serveur, réessayez plus tard" | Contacter l'administrateur |

---

## ✅ Checklist de déploiement

- [x] Mode développement supprimé du code
- [x] URL configurée vers le serveur de production
- [x] Documentation mise à jour
- [x] Tests de connexion effectués
- [ ] Comptes utilisateurs créés en production
- [ ] Certificat SSL vérifié
- [ ] Serveur backend démarré et stable
- [ ] Monitoring des logs activé
- [ ] Plan de backup en place

---

## 📞 Support

En cas de problème de connexion :

1. **Vérifier l'état du serveur**
   ```bash
   curl https://railskills.syl20.org/api/health
   ```

2. **Consulter les logs**
   ```bash
   # Sur le serveur
   tail -f /var/log/railskills/access.log
   tail -f /var/log/railskills/error.log
   ```

3. **Vérifier la base de données**
   ```sql
   -- Se connecter à PostgreSQL
   psql -U railskills -d railskills_db
   
   -- Vérifier la table users
   SELECT email, ctt_id, created_at FROM users;
   ```

---

**Auteur :** Sylvain Gallon  
**Dernière mise à jour :** 26 novembre 2025


