# 🚀 Ajouter le Message Directement via SSH

**Date :** 3 décembre 2025  
**Méthode :** Modification directe via SSH sans Cursor

---

## 🎯 Solution Simple : Modification Directe

Puisque le site web n'est pas accessible depuis Cursor, modifions directement via SSH.

---

## 📋 Étapes

### Étape 1 : Se Connecter au Mac Mini

Ouvrez un terminal et connectez-vous :

```bash
ssh macmini-railskills
```

### Étape 2 : Naviguer vers le Site Web

```bash
cd /Users/sylvain/Applications/RailSkills/RailSkills-Web
```

### Étape 3 : Trouver le Fichier d'Inscription

Cherchez le fichier du formulaire d'inscription :

```bash
# Pour React/TypeScript
find frontend/src -name "*Register*.tsx" -o -name "*SignUp*.tsx"
find frontend/src -name "*register*.tsx" -o -name "*signup*.tsx"

# Pour tous les fichiers
find . -name "*register*" -o -name "*signup*"
```

### Étape 4 : Ouvrir le Fichier

Ouvrez le fichier trouvé avec votre éditeur préféré :

```bash
# Avec nano (éditeur simple)
nano frontend/src/components/Auth/RegisterForm.tsx

# Avec vim (si vous le préférez)
vim frontend/src/components/Auth/RegisterForm.tsx

# Avec VS Code (si installé sur le Mac mini)
code frontend/src/components/Auth/RegisterForm.tsx
```

### Étape 5 : Ajouter le Message

Trouvez le bouton de soumission dans le fichier et ajoutez le message **juste avant**.

---

## 💻 Code à Ajouter

### Pour React/TypeScript (.tsx)

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

## 📍 Où Placer le Code ?

Le message doit être ajouté **juste avant le bouton de soumission** :

```tsx
<form onSubmit={handleSubmit}>
  {/* Champs du formulaire */}
  <input type="email" ... />
  <input type="text" ... />
  
  {/* ⚠️ AJOUTER LE MESSAGE ICI */}
  <div className="alert alert-info ...">
    ...
  </div>
  
  {/* Bouton de soumission */}
  <button type="submit">Créer mon compte</button>
</form>
```

---

## 🔧 Alternative : Utiliser Cursor IA sur le Serveur

Si vous préférez utiliser Cursor IA directement sur le serveur :

### Option 1 : Ouvrir Cursor depuis SSH

1. **Connectez-vous via SSH** :
   ```bash
   ssh macmini-railskills
   ```

2. **Naviguez vers le dossier** :
   ```bash
   cd /Users/sylvain/Applications/RailSkills/RailSkills-Web
   ```

3. **Ouvrez avec Cursor** (si installé sur le Mac mini) :
   ```bash
   cursor .
   ```

   Ou avec VS Code :
   ```bash
   code .
   ```

4. **Utilisez le prompt** dans `PROMPT_A_COPIER.txt`

### Option 2 : Utiliser Remote-SSH dans Cursor Local

1. Dans Cursor local, appuyez sur `Cmd + Shift + P`
2. Tapez : `Remote-SSH: Connect to Host...`
3. Sélectionnez : `macmini-railskills`
4. Une nouvelle fenêtre Cursor s'ouvre connectée au serveur
5. Ouvrez le dossier : `/Users/sylvain/Applications/RailSkills/RailSkills-Web`

---

## 📝 Exemple Complet avec nano

Voici comment modifier avec nano (éditeur simple) :

```bash
# 1. Se connecter
ssh macmini-railskills

# 2. Aller dans le dossier
cd /Users/sylvain/Applications/RailSkills/RailSkills-Web

# 3. Trouver le fichier (exemple)
find . -name "*Register*.tsx"

# 4. Ouvrir le fichier
nano frontend/src/components/Auth/RegisterForm.tsx

# 5. Dans nano :
#    - Naviguez avec les flèches
#    - Trouvez le bouton "Créer mon compte"
#    - Ajoutez le code juste avant
#    - Sauvegardez : Ctrl+O puis Entrée
#    - Quittez : Ctrl+X
```

---

## ✅ Vérification

Après avoir ajouté le message :

1. ✅ Sauvegardez le fichier
2. ✅ Vérifiez que le code est bien ajouté
3. ✅ Testez le site web dans le navigateur
4. ✅ Vérifiez que le message s'affiche correctement

---

## 🆘 Besoin d'Aide ?

Si vous avez besoin d'aide pour :
- Trouver le bon fichier
- Ajouter le code au bon endroit
- Utiliser l'éditeur

Dites-moi et je vous guiderai étape par étape !

---

**Guide prêt ! Utilisez SSH pour modifier directement. 🚀**








