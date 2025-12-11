# ⚡ Guide Rapide - Synchronisation Conducteurs SharePoint

## 🎯 Problème : Les conducteurs ne se synchronisent pas

### ✅ Solution en 3 étapes

---

## Étape 1 : Vérifier la configuration (30 sec)

### Sur l'iPad, ouvrir :
```
⚙️ Réglages → Synchronisation SharePoint
```

### Vérifier 3 choses :

1. **État** : Doit afficher `✓ Configuré`
   - ❌ Si "Non configuré" → [Aller à la section Configuration](#configuration-initiale)

2. **Synchronisation automatique** : Doit être `☑️ ACTIVÉ`
   - ❌ Si désactivé → Activer le toggle

3. **Dernière synchronisation** : Affiche une date
   - ❌ Si "Jamais" → [Aller à l'étape 2](#étape-2--forcer-la-synchronisation-10-sec)

---

## Étape 2 : Forcer la synchronisation (10 sec)

### Dans Synchronisation SharePoint :

1. Scroller vers le bas
2. Cliquer sur **"Synchroniser les conducteurs uniquement"**
3. Attendre le message de confirmation

### Messages possibles :

✅ **"X conducteur(s) synchronisé(s)"**
→ **SUCCÈS !** Vos conducteurs sont sur SharePoint

❌ **Erreur affichée**
→ Noter le message et [voir les solutions d'erreur](#solutions-des-erreurs-courantes)

---

## Étape 3 : Vérifier sur SharePoint (1 min)

### Se connecter à SharePoint :
```
https://sncf.sharepoint.com/sites/railskillsgrpo365
```

### Naviguer vers :
```
Documents → RailSkills → Data
```

### Vérifier :
- ✅ Un dossier par conducteur apparaît
- ✅ Chaque dossier contient un fichier `.json`

**Exemple** :
```
Data/
├── Jean_Dupont/
│   └── Jean_Dupont.json
├── Marie_Martin/
│   └── Marie_Martin.json
└── Pierre_Bernard/
    └── Pierre_Bernard.json
```

---

## Configuration initiale

Si SharePoint n'est **PAS configuré** :

### 1. Obtenir le Client Secret

Le Client Secret vous a été fourni par l'administrateur Azure AD.
Si vous ne l'avez pas, contactez votre administrateur.

### 2. Configurer dans l'app

```
⚙️ Réglages → Synchronisation SharePoint → Configuration Azure AD
```

1. Entrer le **Client Secret**
2. Cliquer sur **"Enregistrer"**
3. Cliquer sur **"Tester la connexion"**

### 3. Résultat attendu

✅ **"Connexion réussie"**
→ Retourner à l'[Étape 2](#étape-2--forcer-la-synchronisation-10-sec)

❌ **Erreur**
→ Vérifier que le Client Secret est correct

---

## Solutions des erreurs courantes

### ❌ "Non configuré"
**Cause** : Client Secret manquant

**Solution** : Aller dans [Configuration initiale](#configuration-initiale)

---

### ❌ "Unauthorized 401"
**Cause** : Client Secret incorrect ou expiré

**Solution** :
1. Demander un nouveau Client Secret à l'administrateur
2. Re-configurer dans l'app
3. Re-tester

---

### ❌ "Network error" / "Connexion impossible"
**Cause** : Pas de connexion Internet

**Solution** :
1. Vérifier le WiFi ou 4G/5G
2. Ouvrir un navigateur pour tester Internet
3. Réessayer la synchronisation

---

### ❌ "Site not found"
**Cause** : Permissions insuffisantes sur SharePoint

**Solution** :
1. Vérifier avec l'administrateur que vous avez accès au site :
   `https://sncf.sharepoint.com/sites/railskillsgrpo365`
2. Vérifier les permissions de l'application Azure AD

---

### ❌ "No drivers to sync"
**Cause** : Aucun conducteur sur l'iPad

**Solution** :
1. Aller dans l'onglet **Gestion** (icône personnes)
2. Ajouter au moins un conducteur avec le bouton **+**
3. Réessayer la synchronisation

---

## 🔄 Déclencher automatiquement la synchronisation

La synchronisation automatique se déclenche **automatiquement** après :

✅ Ajout d'un conducteur
✅ Modification d'un conducteur
✅ Suppression d'un conducteur
✅ Modification des dates d'évaluation
✅ Changement des états de checklist

**Délai** : 2 secondes après la modification

---

## 📱 Indicateur de synchronisation

### Dans l'app (coin supérieur droit) :

- 🟢 **Cercle vert** : Synchronisation réussie
- 🟡 **Cercle jaune** : Synchronisation en cours...
- 🔴 **Cercle rouge** : Erreur de synchronisation

### Détails complets :

```
⚙️ Réglages → Synchronisation SharePoint
```

Affiche :
- Date de dernière synchronisation
- Nombre de conducteurs synchronisés
- Messages d'erreur détaillés

---

## ⚠️ Points importants

1. **Connexion Internet requise**
   - SharePoint nécessite Internet (WiFi ou 4G/5G)
   - La synchronisation échoue sans connexion

2. **Synchronisation automatique activée par défaut**
   - Pas besoin de configuration supplémentaire
   - Fonctionne en arrière-plan

3. **Un dossier par conducteur**
   - Structure organisée sur SharePoint
   - Facile à retrouver et gérer

4. **Sécurité**
   - Client Secret stocké dans Keychain iOS
   - Connexion sécurisée via Azure AD
   - Données transmises en HTTPS

---

## 🆘 Aide supplémentaire

Si le problème persiste après ces étapes :

1. **Consulter** : [DIAGNOSTIC_SHAREPOINT_CONDUCTEURS.md](DIAGNOSTIC_SHAREPOINT_CONDUCTEURS.md)
   - Diagnostic complet et détaillé
   - Tous les cas d'erreur possibles

2. **Redémarrer l'application**
   - Fermer complètement RailSkills
   - Relancer
   - Réessayer la synchronisation

3. **Contacter le support**
   - Fournir le message d'erreur exact
   - Indiquer le nombre de conducteurs
   - Préciser si la configuration a déjà fonctionné avant

---

**Temps total estimé** : 2-3 minutes  
**Niveau** : Facile  
**Prérequis** : Client Secret Azure AD



