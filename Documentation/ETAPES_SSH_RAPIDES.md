# ⚡ Étapes Rapides via SSH

**Date :** 3 décembre 2025

---

## 🚀 Commandes à Exécuter dans Votre Terminal

### Étape 1 : Se Connecter

```bash
ssh macmini-railskills
```

### Étape 2 : Aller dans le Dossier du Site Web

```bash
cd /Users/sylvain/Applications/RailSkills/RailSkills-Web
```

### Étape 3 : Trouver le Fichier d'Inscription

```bash
# Chercher les fichiers React/TypeScript
find frontend/src -name "*Register*.tsx" -o -name "*SignUp*.tsx"

# Ou chercher tous les fichiers
find . -name "*register*" -o -name "*signup*" | head -10
```

### Étape 4 : Ouvrir le Fichier avec Cursor (si installé sur le Mac mini)

```bash
cursor frontend/src/components/Auth/RegisterForm.tsx
```

**OU** avec VS Code :

```bash
code frontend/src/components/Auth/RegisterForm.tsx
```

**OU** avec nano (éditeur simple) :

```bash
nano frontend/src/components/Auth/RegisterForm.tsx
```

---

## 📝 Dans Cursor/VS Code (sur le Mac mini)

Une fois le fichier ouvert, utilisez le prompt de `PROMPT_A_COPIER.txt` :

```
Ajoute un message d'information dans le formulaire de création de compte, juste avant le bouton de soumission.

Le message doit afficher :
- Titre : "Visibilité des données"
- Texte : "Les données saisies dans RailSkills pourront être consultées par votre encadrement pour le suivi triennal réglementaire."
- Icône : ℹ️ (info)

Le message doit être bien visible avec un style d'alerte (alert-info), placé après tous les champs de saisie mais avant le bouton "Créer mon compte" ou "Create account".

Utilise le style Bootstrap si disponible (alert alert-info), sinon crée un style similaire avec une bordure gauche bleue et un fond clair.

Le texte doit être identique à celui de l'application iOS pour garantir la cohérence.
```

---

## 💻 Code à Ajouter Manuellement (si nécessaire)

Si vous devez ajouter le code manuellement, placez-le **juste avant le bouton de soumission** :

```tsx
{/* Message de visibilité des données */}
<div className="alert alert-info d-flex align-items-start mb-4" role="alert">
  <i className="bi bi-info-circle-fill me-3" style={{ fontSize: '1.5rem' }} />
  <div>
    <h6 className="alert-heading mb-2">Visibilité des données</h6>
    <p className="mb-0">
      Les données saisies dans RailSkills pourront être consultées par votre 
      encadrement pour le suivi triennal réglementaire.
    </p>
  </div>
</div>
```

---

## ✅ Checklist

- [ ] Connecté au Mac mini via SSH
- [ ] Navigué vers le dossier RailSkills-Web
- [ ] Trouvé le fichier d'inscription
- [ ] Ouvert le fichier dans un éditeur
- [ ] Ajouté le message avant le bouton de soumission
- [ ] Sauvegardé le fichier
- [ ] Vérifié que le message s'affiche correctement

---

**Étapes rapides prêtes ! Exécutez-les dans votre terminal. ⚡**









