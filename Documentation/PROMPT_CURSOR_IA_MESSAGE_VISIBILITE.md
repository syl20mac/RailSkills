# 💬 Prompt pour Cursor IA - Ajouter le Message de Visibilité

**Date :** 3 décembre 2025  
**Usage :** Copier-coller ce prompt dans Cursor IA sur le second onglet (site web)

---

## 🎯 Prompt Principal (Recommandé)

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

## 📋 Prompt Détaillé (Alternative)

```
Je dois ajouter un message d'information sur la visibilité des données dans le formulaire de création de compte.

CONTEXTE :
- Cette application est RailSkills-Web, une application web pour le suivi triennal réglementaire
- L'application iOS a déjà ce message dans son formulaire d'inscription
- Je dois ajouter le même message pour cohérence

MESSAGE À AJOUTER :
Titre : "Visibilité des données"
Texte : "Les données saisies dans RailSkills pourront être consultées par votre encadrement pour le suivi triennal réglementaire."
Icône : ℹ️ ou une icône d'information

REQUIREMENTS :
1. Placer le message juste avant le bouton de soumission du formulaire
2. Après tous les champs de saisie (email, nom, mot de passe, etc.)
3. Utiliser un style d'alerte bien visible (comme Bootstrap alert-info)
4. Le texte doit être EXACTEMENT le même que l'application iOS
5. Le message doit être responsive et accessible

STYLE :
- Si Bootstrap est disponible : utiliser "alert alert-info"
- Sinon : créer un style similaire avec bordure gauche bleue et fond clair
- Icône d'information à gauche du texte

Merci de trouver le formulaire d'inscription et d'ajouter ce message.
```

---

## 🎨 Prompt avec Exemple de Code

```
Ajoute ce message d'information dans le formulaire de création de compte, juste avant le bouton de soumission :

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

Si c'est du HTML/PHP, utilise cette version :

```html
<div class="alert alert-info d-flex align-items-start mb-4" role="alert">
    <i class="bi bi-info-circle-fill me-3" style="font-size: 1.5rem;"></i>
    <div>
        <h6 class="alert-heading mb-2">Visibilité des données</h6>
        <p class="mb-0">
            Les données saisies dans RailSkills pourront être consultées par votre 
            encadrement pour le suivi triennal réglementaire.
        </p>
    </div>
</div>
```

Trouve le formulaire d'inscription et ajoute ce message juste avant le bouton de soumission.
```

---

## 🚀 Prompt Court (Version Rapide)

```
Ajoute un message d'alerte d'information dans le formulaire de création de compte, juste avant le bouton de soumission, avec ce texte :

Titre : "Visibilité des données"
Message : "Les données saisies dans RailSkills pourront être consultées par votre encadrement pour le suivi triennal réglementaire."

Utilise un style d'alerte (alert-info) bien visible.
```

---

## 💡 Instructions d'Utilisation

### Étape 1 : Ouvrir le Bon Fichier

1. Dans le **second onglet** (site web), ouvrez le fichier du formulaire d'inscription
2. Cherchez le fichier qui contient le formulaire de création de compte

### Étape 2 : Utiliser le Prompt

1. **Sélectionnez tout le code** du formulaire (ou au moins la partie avec les champs et le bouton)
2. **Ouvrez Cursor IA** (Cmd+K ou Ctrl+K)
3. **Copiez-collez un des prompts ci-dessus**
4. **Appuyez sur Entrée** pour exécuter

### Étape 3 : Vérifier

1. Cursor IA va ajouter le message
2. **Vérifiez** que le message est bien placé avant le bouton
3. **Vérifiez** que le texte est exactement le même que l'application iOS
4. **Testez** visuellement que le message s'affiche correctement

---

## 🎯 Quel Prompt Utiliser ?

### Utilisez le Prompt Principal si :
- ✅ Vous voulez quelque chose de clair et direct
- ✅ Cursor IA doit trouver le formulaire automatiquement
- ✅ Vous voulez un résultat rapide

### Utilisez le Prompt Détaillé si :
- ✅ Vous voulez plus de contrôle
- ✅ Vous voulez expliquer le contexte
- ✅ Cursor IA a besoin de plus d'informations

### Utilisez le Prompt avec Exemple si :
- ✅ Vous voulez un résultat précis
- ✅ Vous avez déjà le code exact
- ✅ Vous voulez que Cursor IA utilise votre code

### Utilisez le Prompt Court si :
- ✅ Vous voulez quelque chose de très rapide
- ✅ Cursor IA connaît déjà bien votre code
- ✅ Vous êtes pressé

---

## ✅ Après l'Exécution

Une fois que Cursor IA a ajouté le message, vérifiez :

1. ✅ Le message apparaît avant le bouton "Créer mon compte"
2. ✅ Le texte est identique à l'application iOS
3. ✅ Le style est cohérent avec le reste du site
4. ✅ Le message est bien visible
5. ✅ Le code est propre et bien formaté

---

## 🆘 Si Ça Ne Fonctionne Pas

Si Cursor IA ne trouve pas le bon fichier ou ne comprend pas :

1. **Ouvrez d'abord le fichier** du formulaire d'inscription
2. **Sélectionnez le code** autour du bouton de soumission
3. **Répétez le prompt** en précisant "dans le code sélectionné"

Ou utilisez ce prompt plus spécifique :

```
Dans le code sélectionné, ajoute ce message d'alerte juste avant le bouton de soumission du formulaire :

[Coller ici le code du message]
```

---

**Prompt prêt à utiliser ! Copiez-collez dans Cursor IA sur le second onglet. 💬**








