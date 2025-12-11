# Guide : Modification du Backend et Site Web RailSkills

## Objectif

Ajouter au backend les endpoints pour que l'app iOS puisse :
1. Obtenir des tokens SharePoint (sans connaitre le Client Secret)
2. Synchroniser le secret de chiffrement organisationnel

---

## Fichiers crees

| Fichier | Usage |
|---------|-------|
| `PROMPT_CURSOR_BACKEND_COMPLET.md` | Prompt detaille avec tout le code |
| `PROMPT_CURSOR_COURT_BACKEND.txt` | Version courte a copier-coller |

---

## Utilisation sur le Mac mini

### Etape 1 : Ouvrir le projet backend dans Cursor

```bash
cd ~/chemin/vers/backend
cursor .
```

### Etape 2 : Copier le prompt

1. Ouvrir `PROMPT_CURSOR_COURT_BACKEND.txt`
2. Selectionner tout le contenu (Cmd+A)
3. Copier (Cmd+C)

### Etape 3 : Utiliser Cursor AI

1. Appuyer sur Cmd+L pour ouvrir le chat Cursor
2. Coller le prompt (Cmd+V)
3. Appuyer sur Entree
4. Cursor va proposer les modifications

### Etape 4 : Verifier et appliquer

1. Relire le code propose
2. Cliquer sur Apply pour chaque fichier
3. Verifier les logs du serveur

---

## Configuration requise

Variables d'environnement a ajouter dans .env :

```env
AZURE_TENANT_ID=4a7c8238-5799-4b16-9fc6-9ad8fce5a7d9
AZURE_CLIENT_ID=bd394412-97bf-4513-a59f-e023b010dff7
AZURE_CLIENT_SECRET=VOTRE_SECRET_ICI
ORGANIZATION_NAME=SNCF Traction
ORGANIZATION_SECRET=ChoisirUnSecretFort2024
```

---

## Tests apres modification

```bash
# Test 1 : Health check
curl http://localhost:3000/api/health

# Test 2 : Token SharePoint
curl -X POST http://localhost:3000/api/sharepoint/token

# Test 3 : Secret organisationnel
curl http://localhost:3000/api/organization/secret
```

---

## Checklist finale

- Endpoints ajoutes au backend
- Variables .env configurees
- Tests curl passent
- Logs OK apres 5 min
- Test depuis app iOS reussi

