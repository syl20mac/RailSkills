# 📱 RailSkills - Guide de Fonctionnement Simple

**Version :** 2.1  
**Date :** Novembre 2025

---

## 📖 Table des matières

1. [Qu'est-ce que RailSkills ?](#quest-ce-que-railskills)
2. [Comment fonctionne l'application ?](#comment-fonctionne-lapplication)
3. [Où sont stockées les données ?](#où-sont-stockées-les-données)
4. [Le chiffrement expliqué simplement](#le-chiffrement-expliqué-simplement)
5. [Les différentes fonctions de l'application](#les-différentes-fonctions-de-lapplication)
6. [Comment partager des données ?](#comment-partager-des-données)
7. [Questions fréquentes](#questions-fréquentes)

---

## 🎯 Qu'est-ce que RailSkills ? {#quest-ce-que-railskills}

**RailSkills** est une application mobile pour iPad et iPhone qui permet aux **Cadres Transport Traction (CTT)** et aux **Adjoints Référents Conduite (ARC)** de suivre les compétences des conducteurs SNCF circulant au Luxembourg.

### À quoi sert-elle ?

Imaginez un **carnet de suivi numérique** pour chaque conducteur. L'application permet de :

- ✅ Suivre la progression des évaluations (questions validées, partielles, non validées)
- ✅ Ajouter des notes et des commentaires pour chaque question
- ✅ Voir d'un coup d'œil quels conducteurs ont des échéances proches
- ✅ Partager les données avec d'autres collègues
- ✅ Générer des rapports PDF pour impression ou archivage
- ✅ Exporter les données pour traitement dans Excel

### L'application est-elle vide au départ ?

**Oui, c'est normal !** RailSkills démarre avec **aucune donnée** pour garantir la confidentialité. Vous devez :

1. Importer ou créer une checklist (liste de questions à évaluer)
2. Ajouter des conducteurs
3. Commencer le suivi

---

## 🔄 Comment fonctionne l'application ? {#comment-fonctionne-lapplication}

### Structure de l'application

L'application est organisée en **6 onglets** :

#### **Onglet 1 : Suivi** 📋
C'est l'écran principal. Vous y voyez :
- La liste des conducteurs (en haut)
- La progression globale du conducteur sélectionné (graphique circulaire)
- Les catégories de questions (ex: "Connaissances théoriques", "Pratique opérationnelle")
- Les questions avec leurs états (☐ Non validé, ◪ Partiel, ☑ Validé, ⊘ Non applicable)

**Comment changer l'état d'une question ?**
- Sur iPhone : glissez horizontalement sur la question ou tapez pour incrémenter
- Sur iPad : utilisez le contrôle sélectionné (toggle, segments, boutons, ou menu)

**Comment ajouter une note ?**
Tapez sur l'icône 📝 à côté de la question et saisissez votre note.

#### **Onglet 2 : Éditeur** ✏️
Ici, vous pouvez :
- Créer ou modifier la checklist (ajouter des catégories, des questions)
- Gérer les conducteurs (ajouter, modifier, supprimer)
- Importer une checklist depuis un fichier JSON ou texte

#### **Onglet 3 : Partage** 🔄
Permet d'exporter et d'importer des données :
- **Exporter** : JSON, CSV (Excel), PDF, ou QR code
- **Importer** : Fichier JSON ou scanner un QR code

#### **Onglet 4 : Dashboard** 📊
Vue d'ensemble avec :
- Statistiques globales (nombre de conducteurs, questions, progression moyenne)
- Liste des échéances triennales (avec codes couleur : vert = OK, orange = attention, rouge = urgent)

#### **Onglet 5 : Rapports** 📄
Génère des rapports PDF professionnels avec :
- Page de couverture
- Détail complet par conducteur
- Synthèse statistique

#### **Onglet 6 : Réglages** ⚙️
Configuration de l'application :
- Mode d'interaction (comment changer l'état des questions)
- Synchronisation iCloud
- Gestion du chiffrement (secret organisationnel)
- Statistiques

### Comment les données sont-elles sauvegardées ?

**Tout est automatique !** Dès que vous :
- Changez l'état d'une question
- Ajoutez une note
- Modifiez un conducteur

Les données sont **immédiatement sauvegardées** sur votre appareil. Aucun bouton "Enregistrer" n'est nécessaire.

---

## 💾 Où sont stockées les données ? {#où-sont-stockées-les-données}

### Stockage local (par défaut)

Toutes les données sont stockées **sur votre iPad ou iPhone** dans un espace privé de l'application. C'est comme un tiroir fermé à clé que seul RailSkills peut ouvrir.

**Avantages :**
- ✅ Aucune connexion Internet nécessaire
- ✅ Fonctionne même hors ligne
- ✅ Données 100% privées et locales

### Synchronisation iCloud (optionnelle)

Si vous activez iCloud dans les réglages, vos données sont également copiées sur votre compte iCloud.

**Avantages :**
- ✅ Accessible sur plusieurs appareils (ex: votre iPhone ET votre iPad)
- ✅ Sauvegarde automatique dans le cloud
- ✅ Synchronisation automatique entre appareils

**Comment ça marche ?**
Quand vous modifiez quelque chose sur un appareil, les changements sont automatiquement copiés sur iCloud, puis synchronisés sur vos autres appareils connectés au même compte iCloud.

**⚠️ Important :** iCloud nécessite un compte iCloud actif et une connexion Internet.

---

## 🔐 Le chiffrement expliqué simplement {#le-chiffrement-expliqué-simplement}

### Qu'est-ce que le chiffrement ?

Le **chiffrement** transforme vos données en quelque chose d'incompréhensible pour quelqu'un qui n'a pas la "clé" pour les déchiffrer.

**Analogie simple :**
Imaginez que vous envoyez une lettre secrète :
- **Sans chiffrement** : Tout le monde peut lire votre lettre si elle est interceptée
- **Avec chiffrement** : Votre lettre est écrite dans un code secret. Seule la personne qui connaît le code peut la lire

### Comment fonctionne le chiffrement dans RailSkills ?

#### 1. Le secret organisationnel

RailSkills utilise un **"secret organisationnel"** pour créer la clé de chiffrement. C'est comme un mot de passe partagé entre tous les appareils de votre organisation.

**Par défaut**, l'application utilise un secret prédéfini. Mais vous pouvez en créer un **personnalisé** dans les Réglages.

**Pourquoi un secret personnalisé ?**
- ✅ Plus de sécurité (personne d'extérieur ne peut déchiffrer vos exports)
- ✅ Vous contrôlez qui peut lire vos données partagées
- ✅ Seuls les appareils avec le même secret peuvent déchiffrer

#### 2. Le processus de chiffrement

Quand vous **exportez** un conducteur en JSON avec chiffrement :

1. **Étape 1 : Compression** (optionnelle)
   - Les données sont compressées (réduites en taille) pour prendre moins de place
   - C'est comme zipper un fichier

2. **Étape 2 : Chiffrement**
   - Le secret organisationnel est transformé en une clé de chiffrement
   - Les données sont chiffrées avec cette clé
   - Un "nonce" (numéro unique) est ajouté pour garantir que chaque chiffrement est différent

3. **Étape 3 : Stockage**
   - Les données chiffrées sont sauvegardées dans le fichier JSON
   - Sans le secret, impossible de lire le contenu

#### 3. Le processus de déchiffrement

Quand vous **importez** un fichier JSON chiffré :

1. **Détection automatique**
   - L'application détecte automatiquement si le fichier est chiffré

2. **Déchiffrement**
   - Si votre appareil a le même secret que celui qui a créé le fichier, il peut déchiffrer
   - Les données sont décodées et affichées normalement

3. **Décompression** (si nécessaire)
   - Si les données étaient compressées, elles sont automatiquement décompressées

**⚠️ Que se passe-t-il si le secret ne correspond pas ?**
L'import échoue avec un message d'erreur. Vous devez vous assurer que l'appareil qui exporte et l'appareil qui importe ont le **même secret organisationnel**.

#### 4. Gérer le secret dans l'application

Dans **Réglages → Gestion des clés de chiffrement**, vous pouvez :

- **Voir le secret actuel** : Affiché sous forme de QR code
- **Modifier le secret** : Saisir un nouveau secret (doit être identique sur tous les appareils)
- **Partager le secret** : Générer un QR code du secret pour le partager avec d'autres appareils
- **Scanner le secret** : Utiliser la caméra pour scanner un QR code de secret depuis un autre appareil
- **Réinitialiser** : Revenir au secret par défaut (perd l'accès aux fichiers chiffrés avec l'ancien secret)

**💡 Astuce :** Le secret doit être exactement le même sur tous les appareils qui partagent des données. Un simple espace ou caractère différent empêchera le déchiffrement.

---

## 🛠️ Les différentes fonctions de l'application {#les-différentes-fonctions-de-lapplication}

### 1. Suivi des conducteurs

#### Ajouter un conducteur
1. Aller dans **Éditeur** → Section "Conducteurs"**
2. Tapoter **"Ajouter un conducteur"**
3. Remplir le formulaire :
   - **Nom** (obligatoire)
   - **Date de début triennale** (optionnelle mais recommandée)
4. Tapoter **"Enregistrer"**

#### Évaluer une question
1. Dans l'onglet **Suivi**, sélectionner un conducteur
2. Trouver la question dans la catégorie correspondante
3. Changer l'état :
   - ☐ **Non validé** : Pas encore évalué
   - ◪ **Partiel** : En cours d'évaluation
   - ☑ **Validé** : Compétence acquise
   - ⊘ **Non applicable** : Ne s'applique pas à ce conducteur

**Méthodes disponibles :**
- **Toggle** : Glisser horizontalement ou taper
- **Segment** : Sélectionner directement dans une barre de segments
- **Boutons** : 4 boutons distincts
- **Menu** : Menu déroulant

#### Ajouter une note
1. Tapoter l'icône 📝 à côté d'une question
2. Saisir la note dans l'éditeur
3. Tapoter **"Enregistrer"**
4. La note est automatiquement datée et sauvegardée

#### Rechercher
La barre de recherche en haut de l'écran **Suivi** permet de :
- Rechercher dans les titres des questions
- Rechercher dans les notes de tous les conducteurs

#### Filtrer
Le menu de filtre permet d'afficher uniquement :
- **Tout** : Toutes les questions
- **Validé** : Questions validées (☑)
- **Partiel** : Questions partielles (◪)
- **Non validé** : Questions non validées (☐)
- **Non traité** : Questions sans état défini

### 2. Gestion de la checklist

#### Importer une checklist
1. Aller dans **Éditeur**
2. Tapoter **"Importer une checklist"**
3. Choisir :
   - **Fichier JSON** : Checklist structurée au format JSON
   - **Fichier texte** : Format Markdown simple
   - **QR code** : Scanner un QR code partagé

#### Créer une checklist
1. Aller dans **Éditeur**
2. Tapoter le menu "..." en haut à droite
3. **Ajouter une catégorie** ou **Ajouter une question**
4. Modifier les titres en tapant longuement dessus

#### Modifier une checklist
- **Éditer** : Tapoter longuement sur le titre d'une catégorie ou question
- **Supprimer** : Glisser vers la gauche ou utiliser le bouton de suppression
- **Convertir** : Transformer une catégorie en question (ou vice versa)

### 3. Export de données

#### Exporter un conducteur

**Format JSON :**
1. Aller dans **Partage**
2. Sélectionner le conducteur
3. Tapoter **"Exporter en JSON"**
4. Choisir comment partager (AirDrop, Mail, Fichiers, etc.)
5. Le fichier contient toutes les données du conducteur + la checklist (optionnelle)

**Format CSV (Excel) :**
1. Aller dans **Partage**
2. Sélectionner le conducteur
3. Tapoter **"Exporter en CSV"**
4. Ouvrir le fichier dans Excel ou Numbers
5. Toutes les données sont dans un tableau : une ligne par question

**Format PDF :**
1. Aller dans **Rapports**
2. Sélectionner un ou plusieurs conducteurs
3. Tapoter **"Export de rapport de suivi"**
4. Le PDF contient :
   - Page de couverture avec informations conducteur
   - Table des matières (si plusieurs catégories)
   - Détail complet avec états, notes, dates
   - Synthèse statistique

**QR Code :**
1. Aller dans **Partage**
2. Sélectionner le conducteur
3. Tapoter **"Générer QR code"**
4. Un QR code s'affiche à l'écran
5. L'autre personne scanne ce QR code avec RailSkills pour importer automatiquement

**⚠️ Attention :** Si les données sont trop volumineuses, l'application compresse automatiquement pour le QR code.

#### Exporter plusieurs conducteurs

1. Aller dans **Partage**
2. Tapoter **"Sélectionner les conducteurs"**
3. Cocher les conducteurs à exporter
4. Choisir le format (JSON ou CSV)
5. Partager le fichier

#### Exporter la checklist

1. Aller dans **Partage** → Section "Checklist"
2. Tapoter **"Exporter la checklist"** ou **"Générer QR code"**
3. Partager le fichier ou le QR code

### 4. Import de données

#### Importer des conducteurs depuis un fichier JSON

1. Aller dans **Partage** → Section "Importer"
2. Tapoter **"Importer des conducteurs"**
3. Sélectionner le fichier JSON
4. L'application :
   - Détecte automatiquement si le fichier est chiffré
   - Déchiffre si nécessaire (avec le même secret)
   - Vérifie si le conducteur existe déjà
   - Propose une fusion si nécessaire

**Fusion de conducteurs :**
Si le conducteur existe déjà, vous pouvez choisir :
- **Remplacer tout** : Écraser les données existantes avec les nouvelles
- **Conserver la plus récente** : Garder les données de l'export le plus récent
- **Fusionner** : Combiner les états et notes des deux versions

#### Importer via QR code

1. Aller dans **Partage** → Section "Importer"
2. Tapoter **"Scanner un QR code"**
3. Autoriser l'accès à la caméra
4. Pointer la caméra vers le QR code
5. L'application :
   - Détecte automatiquement si c'est un conducteur ou une checklist
   - Décompresse si nécessaire
   - Importe les données

### 5. Dashboard (Tableau de bord)

Affiche :
- **Statistiques globales** :
  - Nombre total de conducteurs
  - Nombre total de questions dans la checklist
  - Progression moyenne de tous les conducteurs

- **Échéances triennales** :
  - Liste des conducteurs avec leurs échéances
  - Codes couleur :
    - 🟢 **Vert** : Plus de 30 jours restants
    - 🟠 **Orange** : 30 jours ou moins
    - 🔴 **Rouge** : Échéance dépassée

- **Répartition de progression** :
  - Graphique en barres pour le conducteur sélectionné
  - Nombre de questions par état (Validé, Partiel, Non validé, N/A)

### 6. Rapports PDF

1. Aller dans **Rapports**
2. Choisir :
   - **Export de tous les conducteurs** : Génère un PDF avec tous les conducteurs
   - **Export de sélection** : Sélectionner les conducteurs à inclure
3. Le PDF contient :
   - **Page de couverture** : Titre, nom du conducteur, progression globale, échéance triennale
   - **Table des matières** : Si plusieurs catégories (avec numéros de page)
   - **Détail par catégorie** : Toutes les questions avec leurs états, dates de suivi, notes
   - **Synthèse statistique** : Répartition par état, progression par catégorie, pourcentages
   - **En-têtes de page** : Nom de l'application et numéro de page

---

## 📤 Comment partager des données ? {#comment-partager-des-données}

### Méthode 1 : Fichier JSON (avec ou sans chiffrement)

**Avantages :**
- ✅ Peut contenir beaucoup de données
- ✅ Chiffrement optionnel pour sécurité maximale
- ✅ Partageable par email, AirDrop, etc.

**Quand l'utiliser :**
- Partage à distance (email)
- Archivage long terme
- Partage de plusieurs conducteurs

**Comment faire :**
1. Exporter en JSON (avec chiffrement activé par défaut)
2. Partager le fichier
3. L'autre personne importe le fichier dans RailSkills
4. Si chiffré, assurez-vous que les deux appareils ont le même secret

### Méthode 2 : QR Code

**Avantages :**
- ✅ Partage sans réseau (pas besoin d'Internet)
- ✅ Rapide (scan immédiat)
- ✅ Idéal pour partage de proximité

**Limitations :**
- ⚠️ Taille limitée (environ 2900 caractères)
- ⚠️ L'application compresse automatiquement si nécessaire
- ⚠️ Ne peut pas contenir trop de données

**Quand l'utiliser :**
- Partage en face à face (même bureau)
- Partage rapide d'un conducteur
- Partage de checklist

**Comment faire :**
1. Générer le QR code
2. Afficher à l'écran
3. L'autre personne scanne avec RailSkills
4. Import automatique

### Méthode 3 : CSV (Excel)

**Avantages :**
- ✅ Compatible Excel et Numbers
- ✅ Facile à traiter et analyser
- ✅ Tableaux croisés dynamiques possibles

**Quand l'utiliser :**
- Analyse de données dans Excel
- Création de tableaux et graphiques
- Partage avec personnes n'utilisant pas RailSkills

**Comment faire :**
1. Exporter en CSV
2. Ouvrir dans Excel
3. Les données sont dans un tableau (une ligne par question)

### Méthode 4 : PDF

**Avantages :**
- ✅ Format professionnel prêt à imprimer
- ✅ Mise en page soignée avec en-têtes et numéros de page
- ✅ Contient toutes les informations (états, notes, dates, statistiques)

**Quand l'utiliser :**
- Impression pour archivage papier
- Présentation à un comité
- Partage avec personnes n'utilisant pas RailSkills

---

## ❓ Questions fréquentes {#questions-fréquentes}

### **Q : Mes données sont-elles sécurisées ?**

**R :** Oui, de plusieurs façons :

1. **Stockage local** : Les données sont dans un espace privé de l'application, inaccessible aux autres applications
2. **Chiffrement optionnel** : Les exports peuvent être chiffrés avec un secret organisationnel
3. **Aucune transmission réseau** : Par défaut, rien n'est envoyé sur Internet (sauf si vous activez iCloud)
4. **Pas de backend externe** : RailSkills ne dépend d'aucun serveur externe

### **Q : Que se passe-t-il si je perds mon appareil ?**

**R :** Cela dépend de votre configuration :

- **Sans iCloud** : Les données sont uniquement sur l'appareil perdu. Il est recommandé de faire des exports réguliers
- **Avec iCloud** : Les données sont synchronisées dans le cloud. Vous pouvez les récupérer sur un nouvel appareil connecté au même compte iCloud

**💡 Conseil :** Faites régulièrement des exports de sauvegarde, même avec iCloud activé.

### **Q : Puis-je utiliser RailSkills sans Internet ?**

**R :** Oui, complètement ! L'application fonctionne **entièrement hors ligne**. Seule la synchronisation iCloud nécessite Internet (et elle est optionnelle).

### **Q : Comment synchroniser mes données entre iPhone et iPad ?**

**R :** 

1. Assurez-vous que les deux appareils utilisent le **même compte iCloud**
2. Activez **"Synchronisation iCloud"** dans Réglages sur les deux appareils
3. Attendez quelques secondes pour la synchronisation automatique

**⚠️ Important :** Les deux appareils doivent avoir le **même secret organisationnel** si vous partagez des fichiers chiffrés.

### **Q : Que faire si un import échoue ?**

**R :** Plusieurs causes possibles :

1. **Fichier chiffré avec un secret différent** : Vérifiez que les deux appareils ont le même secret dans Réglages
2. **Fichier corrompu** : Vérifiez que le fichier n'a pas été modifié
3. **Format invalide** : Assurez-vous que le fichier est bien au format JSON de RailSkills
4. **Données trop volumineuses** : Pour QR code, essayez d'exporter seulement les données essentielles

### **Q : Puis-je supprimer un conducteur par erreur ?**

**R :** La suppression est **définitive**. L'application demande confirmation avant de supprimer. 

**💡 Conseil :** Faites un export avant de supprimer un conducteur important, pour pouvoir le réimporter si besoin.

### **Q : Combien de conducteurs puis-je suivre ?**

**R :** Il n'y a pas de limite technique définie. L'application peut gérer des dizaines de conducteurs sans problème. Si vous avez des centaines de conducteurs, l'application peut ralentir légèrement.

### **Q : Les QR codes fonctionnent-ils entre différentes marques ?**

**R :** Oui ! Les QR codes sont un standard universel. Un QR code généré par RailSkills peut être scanné par n'importe quelle application capable de scanner des QR codes, mais pour importer les données dans RailSkills, il faut utiliser RailSkills.

### **Q : Puis-je utiliser mes données dans Excel ?**

**R :** Oui ! Exportez en CSV depuis l'onglet **Partage**. Le fichier CSV peut être ouvert directement dans Excel ou Numbers, avec toutes les données dans un tableau (une ligne par question).

---

## 📝 Résumé : Le fonctionnement en 5 étapes

1. **Importer une checklist** : Définir les questions à évaluer
2. **Ajouter des conducteurs** : Créer les dossiers de suivi
3. **Évaluer** : Changer l'état des questions et ajouter des notes (sauvegarde automatique)
4. **Consulter** : Utiliser le Dashboard pour voir la vue d'ensemble
5. **Partager** : Exporter en JSON (chiffré), CSV, PDF, ou QR code selon vos besoins

---

**💡 Astuce finale :** RailSkills est conçue pour être **simple et intuitive**. N'hésitez pas à explorer les différentes fonctions. Toutes les actions peuvent être annulées (sauf la suppression définitive, qui demande confirmation).

---

**Dernière mise à jour :** 18 novembre 2025  
**Version application :** 2.1
