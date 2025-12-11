# 📝 Guide d'Ajout du Message de Visibilité - React/TypeScript

**Date :** 3 décembre 2025  
**Framework :** React + TypeScript (RailSkills-Web)

---

## 🎯 Objectif

Ajouter le message de visibilité des données dans le formulaire d'inscription React, identique à l'application iOS.

---

## 📋 Message à Ajouter

```typescript
ℹ️ Visibilité des données

Les données saisies dans RailSkills pourront être consultées par votre 
encadrement pour le suivi triennal réglementaire.
```

---

## 🔍 Où Trouver le Composant d'Inscription

### Fichiers Probables

Chercher dans le frontend React :

```bash
# Dans le répertoire du site web
cd /Users/sylvain/Applications/RailSkills/RailSkills-Web/frontend

# Rechercher les fichiers d'inscription
find src -name "*Register*.tsx" -o -name "*SignUp*.tsx" -o -name "*Signup*.tsx"
find src -name "*register*.tsx" -o -name "*signup*.tsx"

# Ou rechercher dans les composants
find src/components -name "*Auth*.tsx" -o -name "*Register*.tsx"
```

### Emplacements Typiques

- `src/components/Auth/RegisterForm.tsx`
- `src/components/Auth/SignUpForm.tsx`
- `src/pages/Register.tsx`
- `src/pages/SignUp.tsx`
- `src/views/Auth/RegisterView.tsx`

---

## 💻 Code React/TypeScript à Ajouter

### Version avec Composant Simple

```tsx
/**
 * Message d'information sur la visibilité des données
 */
const VisibilityNotice: React.FC = () => {
  return (
    <div className="alert alert-info d-flex align-items-start mb-4" role="alert">
      <i className="bi bi-info-circle-fill me-3" style={{ fontSize: '1.5rem', flexShrink: 0 }} />
      <div>
        <h6 className="alert-heading mb-2">Visibilité des données</h6>
        <p className="mb-0">
          Les données saisies dans RailSkills pourront être consultées par votre 
          encadrement pour le suivi triennal réglementaire.
        </p>
      </div>
    </div>
  );
};

export default VisibilityNotice;
```

### Version avec Styles Inline (sans Bootstrap)

```tsx
/**
 * Message d'information sur la visibilité des données
 */
const VisibilityNotice: React.FC = () => {
  return (
    <div
      style={{
        backgroundColor: 'rgba(0, 123, 255, 0.1)',
        borderLeft: '4px solid #007BFF',
        padding: '16px',
        margin: '16px 0',
        borderRadius: '4px',
        display: 'flex',
        alignItems: 'flex-start',
        gap: '12px'
      }}
      role="alert"
    >
      <span style={{ fontSize: '1.25rem', color: '#007BFF' }}>ℹ️</span>
      <div>
        <strong style={{ display: 'block', marginBottom: '4px' }}>
          Visibilité des données
        </strong>
        <p style={{ margin: 0, color: '#333', fontSize: '0.9rem' }}>
          Les données saisies dans RailSkills pourront être consultées par votre 
          encadrement pour le suivi triennal réglementaire.
        </p>
      </div>
    </div>
  );
};

export default VisibilityNotice;
```

### Version avec Material-UI (si utilisé)

```tsx
import { Alert, AlertTitle } from '@mui/material';
import InfoIcon from '@mui/icons-material/Info';

/**
 * Message d'information sur la visibilité des données
 */
const VisibilityNotice: React.FC = () => {
  return (
    <Alert 
      severity="info" 
      icon={<InfoIcon />}
      sx={{ mb: 3 }}
    >
      <AlertTitle>Visibilité des données</AlertTitle>
      Les données saisies dans RailSkills pourront être consultées par votre 
      encadrement pour le suivi triennal réglementaire.
    </Alert>
  );
};

export default VisibilityNotice;
```

---

## 📝 Exemple d'Intégration Complète

### Dans un Formulaire d'Inscription React

```tsx
import React, { useState } from 'react';

/**
 * Composant de formulaire d'inscription
 */
const RegisterForm: React.FC = () => {
  const [email, setEmail] = useState('');
  const [fullName, setFullName] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    // ... logique d'inscription
    setIsLoading(false);
  };

  return (
    <form onSubmit={handleSubmit} className="register-form">
      <h2>Créer votre compte</h2>

      {/* Champs du formulaire */}
      <div className="form-group">
        <label htmlFor="email">Email professionnel</label>
        <input
          type="email"
          id="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
        />
      </div>

      <div className="form-group">
        <label htmlFor="fullName">Nom complet</label>
        <input
          type="text"
          id="fullName"
          value={fullName}
          onChange={(e) => setFullName(e.target.value)}
          required
        />
      </div>

      {/* ⚠️ MESSAGE DE VISIBILITÉ À AJOUTER ICI */}
      <VisibilityNotice />
      {/* FIN DU MESSAGE */}

      {/* Bouton de soumission */}
      <button 
        type="submit" 
        disabled={isLoading || !email || !fullName || !password}
        className="btn btn-primary"
      >
        {isLoading ? 'Création en cours...' : 'Créer mon compte'}
      </button>
    </form>
  );
};

/**
 * Composant du message de visibilité (à ajouter)
 */
const VisibilityNotice: React.FC = () => {
  return (
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
  );
};

export default RegisterForm;
```

---

## 🎨 Styles SNCF (Optionnel)

Si vous voulez utiliser les couleurs SNCF :

```tsx
const VisibilityNotice: React.FC = () => {
  const sncfStyles = {
    container: {
      backgroundColor: 'rgba(0, 123, 255, 0.1)', // Ceruleen avec transparence
      borderLeft: '4px solid #007BFF', // Ceruleen
      padding: '16px',
      margin: '16px 0',
      borderRadius: '4px',
      display: 'flex',
      alignItems: 'flex-start',
      gap: '12px'
    },
    icon: {
      fontSize: '1.25rem',
      color: '#007BFF' // Ceruleen
    },
    title: {
      color: '#007BFF', // Ceruleen
      fontWeight: 'bold',
      marginBottom: '4px'
    }
  };

  return (
    <div style={sncfStyles.container} role="alert">
      <span style={sncfStyles.icon}>ℹ️</span>
      <div>
        <strong style={sncfStyles.title}>
          Visibilité des données
        </strong>
        <p style={{ margin: 0, color: '#333', fontSize: '0.9rem' }}>
          Les données saisies dans RailSkills pourront être consultées par votre 
          encadrement pour le suivi triennal réglementaire.
        </p>
      </div>
    </div>
  );
};
```

---

## 📍 Placement dans le Formulaire

Le message doit être placé :

```
┌─────────────────────────────────────┐
│ Formulaire d'inscription            │
├─────────────────────────────────────┤
│ Champs de saisie                    │
│ - Email                             │
│ - Nom complet                       │
│ - Mot de passe                      │
├─────────────────────────────────────┤
│ ⚠️ Message de visibilité          │ ← AJOUTER ICI
├─────────────────────────────────────┤
│ Bouton "Créer mon compte"           │
└─────────────────────────────────────┘
```

**Position exacte :**
- **Après** tous les champs de saisie
- **Avant** le bouton de soumission
- **Bien visible** pour l'utilisateur

---

## ✅ Checklist d'Intégration

- [ ] Localiser le composant de formulaire d'inscription
- [ ] Créer le composant `VisibilityNotice` (ou ajouter inline)
- [ ] Importer/utiliser le composant dans le formulaire
- [ ] Placer le message avant le bouton de soumission
- [ ] Tester visuellement (desktop/mobile)
- [ ] Vérifier l'accessibilité (lecteur d'écran)
- [ ] Vérifier la cohérence avec l'application iOS

---

## 🔗 Cohérence avec l'Application iOS

Le message doit être **identique** à celui de l'application iOS :

**iOS (SwiftUI) :**
```
ℹ️ Visibilité des données
Les données saisies dans RailSkills pourront être consultées par votre 
encadrement pour le suivi triennal réglementaire.
```

**Web (React) :**
```
ℹ️ Visibilité des données
Les données saisies dans RailSkills pourront être consultées par votre 
encadrement pour le suivi triennal réglementaire.
```

---

## 🐛 Dépannage

### Problème : Le composant n'apparaît pas

1. Vérifier que le composant est bien importé
2. Vérifier qu'il n'y a pas d'erreurs dans la console
3. Vérifier les styles CSS qui pourraient le masquer

### Problème : Styles non appliqués

1. Vérifier que Bootstrap/Material-UI est bien importé
2. Utiliser les styles inline en fallback
3. Vérifier les classes CSS utilisées

---

**Guide prêt pour l'intégration React ! 📝**









