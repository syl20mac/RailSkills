## PRD – RailSkills-Web (NAS)  
**Application web de traitement des données RailSkills iPad pour CTT**  

Auteur : Sylvain Gallon  
Version : 1.0  
Plateforme cible : Navigateur web (PC / Mac)  
Hébergement : NAS TerraMaster F8SSD (Docker / serveur web)  
Back-end : Node.js / TypeScript (API REST) – hébergé sur le NAS  
Front-end : React / TypeScript (SPA) – servi par le back-end ou Nginx sur le NAS  
Intégrations : Microsoft Graph / SharePoint Online, chiffrement AES-GCM compatible RailSkills iOS  
Date : Novembre 2025  

---

## 1. Objectif du produit

### 1.1 Problème à résoudre

L’application iOS RailSkills permet aux CTT de réaliser les évaluations triennales et de synchroniser les données (conducteurs, checklists, notes) vers SharePoint.  
Cependant, le traitement avancé de ces données (analyse, consolidation multi-conducteurs, préparation de rapports, vues tableaux, exports PC) est difficile directement depuis l’iPad.

### 1.2 Solution proposée

Mettre en place **RailSkills-Web (NAS)**, une application web hébergée sur le NAS TerraMaster du CTT ou de l’unité, permettant :

- de **lire les JSON chiffrés** exportés/synchronisés par RailSkills iOS vers SharePoint,  
- de **les déchiffrer localement** sur le NAS avec le même « secret organisationnel »,  
- de proposer au CTT une **interface web complète** pour :
  - parcourir les conducteurs et leurs suivis,  
  - analyser les checklists (états, notes, dates),  
  - générer des vues tableaux (type Excel) et des exports (CSV / PDF),  
  - préparer des rapports de synthèse par conducteur / par période / par checklist.

Le tout **sans SNCF_ID**, avec une intégration limitée à :

- **Azure AD / Microsoft Graph** pour l’accès aux fichiers sur SharePoint (flow application, type client-credential, comme sur iOS),  
- éventuelle **authentification simple** pour l’accès web (configurable plus tard : HTTP Basic, reverse proxy, ou intégration Azure AD).

---

## 2. Vue d’ensemble fonctionnelle

### 2.1 Rôle principal : CTT / ARC

Le CTT (ou ARC) utilise RailSkills-Web pour :

- **Lister tous les conducteurs** présents dans les exports JSON SharePoint.  
- **Visualiser le détail** des suivis : état de chaque question, notes, dates, progression globale.  
- **Filtrer** par conducteur, checklist, période, état (validé, partiel, non validé, non traité).  
- **Comparer** plusieurs conducteurs sur une même checklist (vue comparée).  
- **Générer** et **exporter** des rapports (CSV / PDF) pour archivage ou impression.  

### 2.2 Positionnement par rapport à RailSkills iOS

- RailSkills iOS : outil de **saisie terrain**, évaluation, notes, synchro SharePoint.  
- RailSkills-Web (NAS) : outil de **consultation / analyse / reporting** sur PC, à partir des données déjà synchronisées.

Les deux restent découplés : le web ne modifie pas les données sur l’iPad, il lit Strictement ce qui est stocké dans SharePoint.

---

## 3. Architecture technique cible

### 3.1 Composants

- **NAS TerraMaster F8SSD**  
  - Hébergement d’un **conteneur Docker** ou d’un service Node.js :  
    - Back-end : API REST en Node.js / TypeScript (ex : Express ou NestJS).  
    - Front-end : app React / TypeScript, buildée en statique et servie par le back-end ou par Nginx.

- **SharePoint Online / OneDrive for Business**  
  - Contient les fichiers JSON chiffrés exportés par RailSkills iOS.  
  - Structure cible (alignée avec `SharePointSyncService` actuel) :

  ```text
  RailSkills/
  ├── Data/
  │   └── {dossier_conducteur}/
  │        ├── {dossier_conducteur}.json           # snapshot courant
  │        └── {dossier_conducteur}_{timestamp}.json  # archives horodatées
  └── Checklists/
      └── {titre_checklist}_{timestamp}.json
  ```

- **Azure AD / Microsoft Graph**  
  - Utilisation d’une application **confidentielle** (client_id + client_secret) pour accéder à SharePoint via Graph (client credential flow).  
  - Même logique fonctionnelle que `AzureADService` dans l’app iOS.

### 3.2 Flux de données

1. RailSkills iOS synchronise vers SharePoint (JSON potentiellement chiffrés via `EncryptionService`).  
2. RailSkills-Web, depuis le NAS :
   - appelle Graph pour **lister** les fichiers dans `RailSkills/Data` et `RailSkills/Checklists`,  
   - **télécharge** les JSON,  
   - **détecte** s’ils sont chiffrés (même logique que `EncryptionService.isEncrypted`),  
   - **déchiffre** si nécessaire avec le **secret organisationnel** configuré sur le NAS,  
   - **parse** les JSON dans des modèles TypeScript (`DriverRecord`, `Checklist`, …),  
   - stocke éventuellement un cache local (en mémoire ou en base légère type SQLite) pour accélérer.

---

## 4. Modèle de données (aligné iOS)

Les modèles du back-end devront être **alignés** avec ceux de l’app iOS pour charger directement les JSON.

### 4.1 DriverRecord (conducteur)

Champs principaux (reprendre les noms exacts de `Models/DriverRecord.swift`) :

- `id: string` (UUID)  
- `name: string`  
- `lastEvaluation?: string (ISO date)`  
- `triennialStart?: string (ISO date)`  
- `checklistStates: { [checklistTitle: string]: { [itemId: string]: number } }`  
- `checklistNotes: { [checklistTitle: string]: { [itemId: string]: string } }`  
- `checklistDates: { [checklistTitle: string]: { [itemId: string]: string (ISO date) } }`  
- `ownerSNCFId?: string | null` (présent dans les anciens fichiers, **à ignorer côté logique Web**).

### 4.2 Checklist / ChecklistItem

- `Checklist` :  
  - `title: string`  
  - `items: ChecklistItem[]`  
  - `ownerSNCFId?: string | null` (rétrocompatibilité, à ignorer côté Web)  

- `ChecklistItem` :  
  - `id: string` (UUID)  
  - `title: string`  
  - `isCategory: boolean`  
  - `checked: boolean` (peu utilisé côté Web, les états sont dans `checklistStates`)  
  - `notes?: string` (notes locales éventuelles, mais le Web se base surtout sur `checklistNotes` des conducteurs).

### 4.3 Modèles dérivés pour le Web

Le back-end Web pourra définir des modèles « enrichis » pour faciliter l’affichage :

- `DriverSummary` : infos synthétiques pour les listes (progression globale, nb de notes, prochaines échéances).  
- `ChecklistStats` : taux de validation par question, par conducteur, par groupe de conducteurs.  
- `EvaluationMatrix` : matrice Conducteur × Question pour les vues comparatives.

---

## 5. Chiffrement / déchiffrement JSON

### 5.1 Rappel iOS – EncryptionService

Sur iOS, `EncryptionService` :

- dérive une clé AES 256 bits via SHA256 du **secret organisationnel** + un salt fixe (`"ctt.RailSkills.encryption.salt"`),  
- chiffre les données avec **AES-GCM**,  
- stocke en sortie un bloc binaire combinant `[nonce (12 bytes)] + [ciphertext + tag]`,  
- détecte si un blob est chiffré via :  
  - taille minimale (≥ 28 octets),  
  - tentative de parse JSON (si JSON valide → considéré comme non chiffré).

### 5.2 Exigences côté Web

Le back-end Node.js doit :

- **reprendre exactement la même dérivation de clé** :  
  - même secret (configuré côté NAS, ex. via variable d’environnement `RAILSKILLS_ORG_SECRET`),  
  - même salt,  
  - SHA256 du `"<secret>.<salt>"`,  
  - utiliser cette valeur comme clé AES 256 bits.
- **supporter le format combiné** AES-GCM : `[nonce (12)] + [ciphertext + tag (16)]`.  
- **implémenter une fonction d’auto-détection** similaire à `isEncrypted(data)` :
  - si taille < 28 → non chiffré,  
  - sinon, essayer de parser en JSON UTF-8 → si OK, considérer comme non chiffré,  
  - sinon, tenter le déchiffrement AES-GCM.

### 5.3 Gestion des erreurs

- Si un fichier ne peut pas être déchiffré (mauvais secret, données corrompues) :
  - le fichier est marqué comme **« illisible »** dans l’UI (avec détail d’erreur côté log serveur),  
  - l’erreur n’interrompt pas le chargement des autres fichiers.

---

## 6. Fonctionnalités côté CTT (UI Web)

### 6.1 Page 1 – Tableau de bord (Dashboard)

**Objectif** : donner une vue synthétique de l’état des suivis.

Fonctionnalités :

- Carte « Nombre total de conducteurs » + progression moyenne globale.  
- Carte « Conducteurs en alerte » (échéance triennale proche ou dépassée – à recalc comme sur iOS).  
- Graphique simple (barres ou donuts) :
  - répartition des états (validé/partiel/non validé/non traité) pour la checklist sélectionnée.  
- Liste des **derniers fichiers importés** depuis SharePoint (nom, date, statut de déchiffrement).

### 6.2 Page 2 – Liste des conducteurs

Fonctionnalités :

- Table principale des conducteurs :  
  - colonnes : Nom, Date dernière évaluation, Jours restants avant échéance, % progression (checklist sélectionnée), Nb de notes.  
  - tri par colonne (clic sur l’entête).  
  - recherche par texte (filtre sur nom).  
- Filtre par :
  - état triennal (Vert / Orange / Rouge),  
  - présence de notes,  
  - checklist (si plusieurs checklists présentes).
- Bouton « **Voir le détail** » → ouvre la page de détail du conducteur.

### 6.3 Page 3 – Détail conducteur

Fonctionnalités :

- En-tête :  
  - Nom du conducteur, ID, dates triennales, progression générale.  
- Tableau de la checklist :  
  - hiérarchie Catégorie > Questions,  
  - pour chaque question : état (0–3), date du dernier suivi, note éventuelle.  
- Panneau latéral ou modal « Notes » : affichage de la note complète + historique si plusieurs imports.  
- Actions :
  - Exporter le détail en **PDF** (mise en page simple pour impression).  
  - Exporter en **CSV** (pour Excel).

### 6.4 Page 4 – Vue comparée / Analyse

Fonctionnalités :

- Sélection multi-conducteurs (checkbox dans la liste).  
- Affichage d’une matrice :

  - Lignes : questions (groupées par catégorie).  
  - Colonnes : conducteurs sélectionnés.  
  - Cellule : état (0–3) + indicateur de note si existante.

- Stats rapides :
  - % de questions validées pour chaque conducteur.  
  - Questions les plus souvent en « partiel » ou « non validé ».

### 6.5 Page 5 – Administration / Paramètres

Fonctionnalités :

- **Configuration SharePoint / Azure AD** (fichier de config sur NAS ou formulaire d’admin) :  
  - Tenant ID, Client ID, Client Secret, URL du site SharePoint, chemin des dossiers (`RailSkills/Data`, `RailSkills/Checklists`).  
- **Secret organisationnel** pour le déchiffrement :  
  - champ texte masqué pour saisir le secret,  
  - test de déchiffrement sur un fichier exemple.  
- Paramètres divers :
  - fréquence de rafraîchissement (si on met en place un cron / job périodique sur NAS),  
  - activation d’un cache local (oui/non).

---

## 7. API Back-end à implémenter (Node.js / TypeScript)

> Tous les endpoints renvoient des réponses JSON.  
> L’authentification HTTP vers le NAS pourra être ajoutée plus tard (proxy inverse, etc.).

### 7.1 Auth / Configuration

- `GET /api/config/sharepoint`  
  - Retourne le statut de la config SharePoint (ok / manquante) et quelques métadonnées.  

- `POST /api/config/sharepoint/test`  
  - Teste la connexion à Graph / SharePoint (appelle un endpoint simple) et renvoie le résultat.  

- `GET /api/config/encryption`  
  - Indique si un secret est configuré côté serveur (sans le renvoyer).  

- `POST /api/config/encryption/test`  
  - Prend un fichier binaire ou un chemin SharePoint en entrée, tente un déchiffrement et renvoie un statut (succès / échec).

### 7.2 Synchronisation / lecture des fichiers

- `POST /api/sync`  
  - Lance un rafraîchissement immédiat :  
    - liste des fichiers JSON dans `RailSkills/Data` et `RailSkills/Checklists`,  
    - téléchargement, (dé)chiffrement, parsing,  
    - mise à jour du cache en mémoire / base.  

- `GET /api/sync/status`  
  - Donne le dernier statut de synchro : date, nombre de fichiers lus, erreurs éventuelles.

### 7.3 Données métiers

- `GET /api/drivers`  
  - Retourne la liste des `DriverSummary`.  
  - Paramètres de requête possibles : filtre texte, état triennal, présence de notes, checklist.  

- `GET /api/drivers/:id`  
  - Retourne le `DriverRecord` complet + données enrichies (progression, stats par checklist).  

- `GET /api/checklists`  
  - Retourne la liste des checklists disponibles (titre, date, nombre de questions).  

- `GET /api/checklists/:title/structure`  
  - Retourne la structure de la checklist (catégories, questions) à partir du JSON importé.

- `POST /api/analysis/comparison`  
  - Corps : `{ driverIds: string[], checklistTitle: string }`  
  - Retour : `EvaluationMatrix` pour la vue comparée.

### 7.4 Export

- `GET /api/export/driver/:id/csv`  
  - Génère un CSV du suivi pour un conducteur donné.  

- `GET /api/export/driver/:id/pdf`  
  - Génère un PDF (simple, avec logo + tableau des questions/états/notes).  

- `POST /api/export/analysis/csv`  
  - Exporte la matrice comparée en CSV.

---

## 8. Contraintes non fonctionnelles

### 8.1 Performance

- Taille cible : quelques centaines de conducteurs, checklists de 100–300 questions.  
- Les appels à Graph doivent être **paginés** si nécessaire.  
- Utiliser un **cache en mémoire** et, si besoin, une base locale (SQLite) pour éviter de re-télécharger tous les fichiers à chaque rafraîchissement.

### 8.2 Sécurité

- Le **Client Secret Azure AD** et le **secret organisationnel** ne doivent jamais être exposés côté front-end.  
- Ils sont stockés côté serveur (fichiers de configuration protégés sur le NAS ou variables d’environnement).  
- Le NAS doit idéalement être placé derrière un reverse proxy avec HTTPS (certificat interne ou Let’s Encrypt).

### 8.3 Maintenabilité

- Back-end et front-end doivent être **strictement typés** (TypeScript) pour faciliter l’évolution.  
- Séparer clairement :
  - module **Graph / SharePoint**,  
  - module **Encryption** (clé dérivée compatible iOS),  
  - module **Parsing / Mapping**,  
  - module **API HTTP**,  
  - module **UI React** (pages et composants).

---

## 9. Étapes de réalisation (pour Cursor / dev futur)

1. **Initialiser** un projet Node.js + TypeScript (Express ou NestJS) + React + TypeScript.  
2. Implémenter le module **AzureAD / Graph** pour :  
   - obtenir un access token,  
   - lister et télécharger des fichiers dans `RailSkills/Data` et `RailSkills/Checklists`.  
3. Implémenter le module **Encryption** côté Node :  
   - dérivation de clé (SHA256 du `<secret>.<salt>`),  
   - AES-GCM (nonce 12 octets, format combiné),  
   - auto-détection chiffré / non chiffré.  
4. Implémenter le module **Parsing** :  
   - map des JSON iOS vers les modèles TypeScript alignés.  
5. Implémenter l’API REST décrite en section 7.  
6. Implémenter le **front React** avec les pages décrites en section 6 (Dashboard, Liste, Détail, Comparaison, Admin).  
7. Packager le tout dans un **Dockerfile** compatible TerraMaster (port HTTP exposé, variables d’environnement pour la config).  
8. Rédiger un petit **README_NAS.md** expliquant comment déployer le conteneur sur le NAS (commande `docker run`, variables à fournir).

---

## 10. Conclusion

RailSkills-Web (NAS) étend l’écosystème RailSkills vers le PC, sans remettre en cause le modèle « app locale + SharePoint » existant.  
En spécifiant clairement l’architecture, les modèles de données, le chiffrement et les endpoints, ce PRD doit permettre à Cursor / à un futur développeur de **générer l’intégralité du site et de son back-end** de manière cohérente avec l’app iOS actuelle.



