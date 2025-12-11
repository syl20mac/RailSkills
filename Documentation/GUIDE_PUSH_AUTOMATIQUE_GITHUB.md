# Guide : Push Automatique vers GitHub dans Cursor AI

Ce guide explique comment automatiser le push de vos changements vers GitHub directement depuis Cursor AI.

## 📋 Prérequis

1. **Dépôt Git initialisé** : Le projet doit être un dépôt Git
2. **Remote GitHub configuré** : Le remote `origin` doit pointer vers votre dépôt GitHub
3. **Permissions Git** : Vous devez avoir les permissions pour push vers le dépôt

## 🚀 Utilisation du Script Automatique

### Scripts Disponibles

1. **`auto-push-github.sh`** : Script complet avec confirmation et messages détaillés
2. **`quick-push.sh`** : Script rapide sans confirmation (idéal pour Cursor AI)

### Méthode 1 : Script Rapide (Recommandé pour Cursor AI)

**Sans confirmation, push immédiat** :

```bash
cd "/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills"
./scripts/quick-push.sh "Votre message de commit"
```

Ou sans message (utilisera un message avec timestamp) :
```bash
./scripts/quick-push.sh
```

### Méthode 2 : Script Complet avec Confirmation

1. **Ouvrir le terminal** dans Cursor AI (`` Ctrl+` `` ou `Cmd+J`)

2. **Exécuter le script** avec un message de commit personnalisé :
   ```bash
   cd "/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills"
   ./scripts/auto-push-github.sh "Votre message de commit"
   ```

3. **Ou sans message** (utilisera un message par défaut) :
   ```bash
   ./scripts/auto-push-github.sh
   ```

### Méthode 2 : Via la Commande Cursor AI

Vous pouvez demander à Cursor AI d'exécuter le script :

```
Exécute le script auto-push-github.sh avec le message "Mise à jour de la documentation"
```

## 📝 Exemples d'Utilisation

### Exemple 1 : Push avec message personnalisé
```bash
./scripts/auto-push-github.sh "Correction des bugs de synchronisation SharePoint"
```

### Exemple 2 : Push rapide
```bash
./scripts/auto-push-github.sh "Mise à jour"
```

### Exemple 3 : Push depuis le dossier parent
```bash
cd "/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills"
chmod +x scripts/auto-push-github.sh
./scripts/auto-push-github.sh "Auto-commit depuis Cursor AI"
```

## 🔧 Configuration Avancée

### Rendre le Script Exécutable

Si le script n'est pas exécutable, utilisez :
```bash
chmod +x scripts/auto-push-github.sh
```

### Désactiver la Confirmation

Pour push automatiquement sans confirmation, modifiez le script et commentez la section de confirmation :

```bash
# Commenter ces lignes dans auto-push-github.sh :
# read -p "Voulez-vous continuer avec le commit et le push? (o/N): " -n 1 -r
# echo
# if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
#     warning "Opération annulée par l'utilisateur"
#     exit 0
# fi
```

### Push Automatique après Chaque Modification

Vous pouvez créer un alias dans votre `.zshrc` ou `.bashrc` :

```bash
alias push-railskills='cd "/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills" && ./scripts/auto-push-github.sh'
```

Puis utilisez simplement :
```bash
push-railskills "Votre message"
```

## 🎯 Intégration avec Cursor AI

### Via les Commandes Cursor

Cursor AI peut exécuter des commandes terminal. Vous pouvez lui demander :

1. **Push simple** :
   ```
   Pousse les changements vers GitHub avec le message "Mise à jour"
   ```

2. **Push avec vérification** :
   ```
   Vérifie les changements Git et pousse vers GitHub si nécessaire
   ```

3. **Push automatique (rapide)** :
   ```
   Exécute le script quick-push.sh avec le message "Mise à jour"
   ```

4. **Push avec confirmation** :
   ```
   Exécute le script auto-push-github.sh avec le message "Mise à jour"
   ```

### Workflow Recommandé

1. **Faire vos modifications** dans Cursor AI
2. **Demander à Cursor AI** : 
   - "Pousse les changements vers GitHub avec le message [votre message]"
   - Ou : "Exécute quick-push.sh avec le message [votre message]"
3. **Cursor AI exécutera** le script automatiquement

### Exemples de Prompts pour Cursor AI

```
Exécute le script quick-push.sh avec le message "Correction des bugs de synchronisation"
```

```
Pousse tous les changements vers GitHub avec le message "Mise à jour de la documentation"
```

```
Utilise quick-push.sh pour pousser vers GitHub
```

## ⚠️ Sécurité et Bonnes Pratiques

### ⚠️ Ne jamais commiter :

- ❌ Secrets (tokens, clés API, mots de passe)
- ❌ Fichiers de configuration avec secrets (`AzureADConfig.swift` avec secrets)
- ❌ Fichiers `.github_token` ou similaires
- ❌ Données sensibles

### ✅ Vérifier avant de push :

Le script affiche le statut Git avant de commiter. Vérifiez toujours que vous ne commitez pas de secrets.

### 🔒 Fichiers Ignorés

Les fichiers suivants sont déjà dans `.gitignore` :
- `Configs/AzureADConfig.swift` (si contient des secrets)
- `.github_token`
- Fichiers de build (`build/`, `DerivedData/`)
- Fichiers temporaires

## 🐛 Dépannage

### Erreur : "Permission denied"

```bash
chmod +x scripts/auto-push-github.sh
```

### Erreur : "Not a git repository"

Assurez-vous d'être dans le bon répertoire :
```bash
cd "/Users/sylvaingallon/Desktop/Railskills rebuild/RailSkills"
```

### Erreur : "Remote origin not found"

Vérifiez le remote :
```bash
git remote -v
```

Si absent, ajoutez-le :
```bash
git remote add origin https://github.com/syl20mac/RailSkills.git
```

### Erreur : "Authentication failed"

1. Vérifiez vos credentials Git
2. Utilisez un Personal Access Token GitHub si nécessaire
3. Configurez Git Credential Manager :
   ```bash
   git config --global credential.helper osxkeychain
   ```

## 📚 Commandes Git Utiles

### Voir le statut
```bash
git status
```

### Voir les changements
```bash
git diff
```

### Annuler le dernier commit (avant push)
```bash
git reset --soft HEAD~1
```

### Voir l'historique
```bash
git log --oneline -10
```

## 🔗 Ressources

- [Documentation Git](https://git-scm.com/doc)
- [GitHub Documentation](https://docs.github.com)
- [Cursor AI Documentation](https://cursor.sh/docs)

---

**Note** : Ce script est conçu pour simplifier le workflow de développement. Pour les releases importantes, utilisez les scripts dédiés dans `scripts/` (tag-release.sh, create-release.sh).
