# 🚀 Guide Rapide - Ajouter le Message de Visibilité

**Date :** 3 décembre 2025

---

## 📋 Message à Ajouter

```
ℹ️ Visibilité des données

Les données saisies dans RailSkills pourront être consultées par votre 
encadrement pour le suivi triennal réglementaire.
```

---

## 🔍 Étape 1 : Trouver le Fichier d'Inscription

Dans le second onglet (site web), cherchez un fichier qui contient :
- "créer un compte" ou "create account"
- "inscription" ou "register" ou "signup"
- Un formulaire avec des champs email, nom, mot de passe

### Fichiers Probables :

**Pour React/TypeScript :**
- `RegisterForm.tsx` ou `Register.tsx`
- `SignUpForm.tsx` ou `SignUp.tsx`
- `Auth/RegisterView.tsx`
- `pages/Register.tsx`

**Pour PHP/HTML :**
- `register.php`
- `signup.php`
- `auth/register.php`

---

## 📍 Étape 2 : Localiser l'Emplacement

Dans le fichier trouvé, cherchez le **bouton de soumission** du formulaire :
- `"Créer mon compte"`
- `"Create account"`
- `<button type="submit">`
- `onSubmit` ou `handleSubmit`

Le message doit être ajouté **JUSTE AVANT** ce bouton.

---

## 💻 Étape 3 : Ajouter le Code

### Pour React (TypeScript/JSX)

Ajoutez ce code **juste avant le bouton de soumission** :

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

### Pour HTML/PHP

Ajoutez ce code **juste avant le bouton de soumission** :

```html
<!-- Message de visibilité des données -->
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

---

## 📝 Exemple d'Intégration

### Structure Avant :

```tsx
<form onSubmit={handleSubmit}>
  {/* Champs du formulaire */}
  <input type="email" ... />
  <input type="text" ... />
  
  {/* Bouton */}
  <button type="submit">Créer mon compte</button>
</form>
```

### Structure Après :

```tsx
<form onSubmit={handleSubmit}>
  {/* Champs du formulaire */}
  <input type="email" ... />
  <input type="text" ... />
  
  {/* ⚠️ MESSAGE AJOUTÉ ICI */}
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
  
  {/* Bouton */}
  <button type="submit">Créer mon compte</button>
</form>
```

---

## ✅ Vérification

Après avoir ajouté le code :

1. ✅ Le message apparaît avant le bouton "Créer mon compte"
2. ✅ Le message est bien visible
3. ✅ Le texte est identique à l'application iOS
4. ✅ L'icône ℹ️ est affichée

---

## 🆘 Besoin d'Aide ?

Si vous avez des questions ou si vous voulez que je vous aide directement :

1. **Dites-moi le nom du fichier** ouvert dans le second onglet
2. **Ou copiez-moi une partie du code** du formulaire
3. **Ou dites-moi quelle erreur vous rencontrez**

Je pourrai alors vous aider plus précisément !

---

**Guide rapide prêt ! 📝**








