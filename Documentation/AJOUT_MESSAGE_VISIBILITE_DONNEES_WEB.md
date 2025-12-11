# 📝 Instructions pour Ajouter le Message de Visibilité des Données sur le Site Web

**Date :** 3 décembre 2025

---

## 🎯 Objectif

Ajouter le même message de visibilité des données que sur l'application iOS dans le formulaire de création de compte du site web RailSkills-Web.

---

## 📋 Message à Ajouter

Le message doit être identique à celui de l'application iOS :

```
ℹ️ Visibilité des données

Les données saisies dans RailSkills pourront être consultées par votre 
encadrement pour le suivi triennal réglementaire.
```

---

## 🔍 Où Ajouter le Message ?

### Option 1 : Formulaire d'inscription (recommandé)

Le message doit être ajouté dans le **formulaire de création de compte**, généralement dans un fichier comme :
- `register.php` ou `signup.php`
- `auth/register.php`
- `includes/register-form.php`
- Ou dans la vue/template correspondante

### Option 2 : Page d'inscription HTML

Si le formulaire est dans une page HTML :
- `register.html`
- `signup.html`
- Ou dans le template principal (ex: `template.php`, `layout.php`)

---

## 💻 Code à Ajouter

### Version HTML Simple

```html
<!-- Message de visibilité des données -->
<div class="alert alert-info" role="alert">
    <div class="d-flex align-items-start">
        <i class="bi bi-info-circle-fill me-2" style="font-size: 1.25rem; color: #0d6efd;"></i>
        <div>
            <strong>Visibilité des données</strong>
            <p class="mb-0 mt-1">
                Les données saisies dans RailSkills pourront être consultées par votre 
                encadrement pour le suivi triennal réglementaire.
            </p>
        </div>
    </div>
</div>
```

### Version avec Bootstrap (si utilisé)

```html
<!-- Message de visibilité des données -->
<div class="alert alert-info d-flex align-items-start mb-4" role="alert">
    <i class="bi bi-info-circle-fill me-3" style="font-size: 1.5rem; flex-shrink: 0;"></i>
    <div>
        <h6 class="alert-heading mb-2">Visibilité des données</h6>
        <p class="mb-0">
            Les données saisies dans RailSkills pourront être consultées par votre 
            encadrement pour le suivi triennal réglementaire.
        </p>
    </div>
</div>
```

### Version CSS Personnalisée (sans Bootstrap)

```html
<!-- Message de visibilité des données -->
<div class="info-box" style="
    background-color: #e7f3ff;
    border-left: 4px solid #0d6efd;
    padding: 16px;
    margin: 16px 0;
    border-radius: 4px;
">
    <div style="display: flex; align-items: flex-start; gap: 12px;">
        <span style="font-size: 1.25rem; color: #0d6efd;">ℹ️</span>
        <div>
            <strong style="display: block; margin-bottom: 4px;">
                Visibilité des données
            </strong>
            <p style="margin: 0; color: #333; font-size: 0.9rem;">
                Les données saisies dans RailSkills pourront être consultées par votre 
                encadrement pour le suivi triennal réglementaire.
            </p>
        </div>
    </div>
</div>
```

---

## 📍 Emplacement dans le Formulaire

Le message doit être placé :

1. **Avant le bouton de soumission** du formulaire
2. **Après les champs de saisie** (email, nom, etc.)
3. **De manière bien visible** pour l'utilisateur

**Structure recommandée :**
```
┌─────────────────────────────────────┐
│ Formulaire d'inscription            │
├─────────────────────────────────────┤
│ Champs de saisie                    │
│ - Email                             │
│ - Nom complet                       │
│ - Autres champs...                  │
├─────────────────────────────────────┤
│ ⚠️ Message de visibilité          │ ← AJOUTER ICI
├─────────────────────────────────────┤
│ Bouton "Créer mon compte"           │
└─────────────────────────────────────┘
```

---

## 🎨 Styles SNCF (si applicable)

Si le site utilise les couleurs SNCF, utiliser :

```css
/* Couleur ceruleen SNCF */
.info-box {
    background-color: rgba(0, 123, 255, 0.1); /* Ceruleen avec transparence */
    border-left: 4px solid #007BFF; /* Ceruleen */
    color: #333;
}

.info-box strong {
    color: #007BFF; /* Ceruleen */
}
```

---

## 🔍 Étapes pour Trouver le Fichier

1. **Connectez-vous au Mac mini via SSH**
2. **Naviguez vers le répertoire du site web :**
   ```bash
   cd /Users/sylvain/Applications/RailSkills/RailSkills-Web
   ```

3. **Recherchez les fichiers d'inscription :**
   ```bash
   # Rechercher les fichiers PHP d'inscription
   find . -name "*register*.php" -o -name "*signup*.php"
   
   # Ou rechercher dans tous les fichiers
   grep -r "créer.*compte\|create.*account\|inscription\|register" . --include="*.php"
   ```

4. **Ouvrez le fichier trouvé** et ajoutez le message avant le bouton de soumission

---

## 📝 Exemple Complet d'Intégration

### Dans un formulaire PHP classique :

```php
<!-- Formulaire d'inscription -->
<form method="POST" action="register.php">
    <!-- Champs du formulaire -->
    <div class="form-group">
        <label for="email">Email</label>
        <input type="email" id="email" name="email" required>
    </div>
    
    <div class="form-group">
        <label for="fullname">Nom complet</label>
        <input type="text" id="fullname" name="fullname" required>
    </div>
    
    <!-- ⚠️ MESSAGE DE VISIBILITÉ À AJOUTER ICI -->
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
    <!-- FIN DU MESSAGE -->
    
    <!-- Bouton de soumission -->
    <button type="submit" class="btn btn-primary">
        Créer mon compte
    </button>
</form>
```

---

## ✅ Checklist d'Intégration

- [ ] Localiser le fichier de formulaire d'inscription
- [ ] Ajouter le message avant le bouton de soumission
- [ ] Utiliser un style cohérent avec le site web
- [ ] Vérifier que le message est bien visible
- [ ] Tester sur différentes tailles d'écran (responsive)
- [ ] Vérifier l'accessibilité (lecteur d'écran)

---

## 🔗 Cohérence avec l'Application iOS

Le message doit être **identique** à celui de l'application iOS pour garantir une expérience utilisateur cohérente :

**Application iOS :**
```
ℹ️ Visibilité des données
Les données saisies dans RailSkills pourront être consultées par votre 
encadrement pour le suivi triennal réglementaire.
```

**Site Web :**
```
ℹ️ Visibilité des données
Les données saisies dans RailSkills pourront être consultées par votre 
encadrement pour le suivi triennal réglementaire.
```

---

## 📞 Support

Si vous avez besoin d'aide pour localiser le fichier ou intégrer le message, n'hésitez pas à demander. Je peux vous aider à :
- Trouver le bon fichier
- Adapter le code selon votre framework/CMS
- Personnaliser le style selon votre design

---

**Document prêt pour l'intégration sur le site web ! 📝**









