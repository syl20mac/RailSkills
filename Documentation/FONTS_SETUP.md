# Configuration de la police AvenirLTStd

## 📋 Instructions d'installation

### 1. Obtenir les fichiers de police

Vous devez obtenir les fichiers `.ttf` ou `.otf` d'AvenirLTStd avec les variantes suivantes :
- `AvenirLTStd-Book.ttf` (léger)
- `AvenirLTStd-Roman.ttf` (normal)
- `AvenirLTStd-Medium.ttf` (moyen)
- `AvenirLTStd-Heavy.ttf` (gras)
- `AvenirLTStd-Black.ttf` (très gras)

**Important** : Assurez-vous d'avoir une licence valide pour utiliser AvenirLTStd dans une application mobile.

### 2. Ajouter les fichiers au projet Xcode

1. Créez un dossier `Fonts/` dans le projet RailSkills (à la racine)
2. Glissez-déposez tous les fichiers `.ttf` dans ce dossier
3. **Cochez "Add to target: RailSkills"** lors de l'ajout
4. Vérifiez que les fichiers apparaissent dans le projet Xcode

### 3. Vérifier Info.plist

Le fichier `Info.plist` a déjà été configuré avec la clé `UIAppFonts` et la liste des polices. Vérifiez que les noms de fichiers correspondent exactement à ceux que vous avez ajoutés.

### 4. Vérifier les noms de fichiers

Les noms dans `Info.plist` doivent correspondre **exactement** aux noms des fichiers ajoutés. Si vos fichiers ont des noms différents (par exemple `AvenirLTStdBook.ttf` au lieu de `AvenirLTStd-Book.ttf`), modifiez `Info.plist` en conséquence.

### 5. Tester l'installation

L'application utilise automatiquement un système de fallback : si AvenirLTStd n'est pas disponible, elle utilisera la police système (Avenir Next) qui est très similaire.

Pour vérifier que les polices sont bien chargées :
1. Compilez et lancez l'application
2. Si les polices ne sont pas disponibles, vous verrez des messages d'avertissement dans les logs
3. L'application fonctionnera quand même avec le fallback système

## 🔧 Utilisation dans le code

### SwiftUI

```swift
// Au lieu de :
.font(.headline)

// Utilisez :
.font(.avenirHeadline)

// Ou avec une taille personnalisée :
.font(.avenir(.heavy, size: 18))
```

### PDF Generation

Les PDFs utilisent automatiquement AvenirLTStd via les méthodes prédéfinies :
- `UIFont.avenirTitlePDF`
- `UIFont.avenirHeaderPDF`
- `UIFont.avenirBodyPDF`
- etc.

## ⚠️ Notes importantes

1. **Licence** : Assurez-vous d'avoir une licence valide pour AvenirLTStd
2. **Noms de fichiers** : Les noms doivent correspondre exactement entre les fichiers et `Info.plist`
3. **Fallback** : L'application fonctionnera même sans les polices grâce au système de fallback
4. **Taille de l'app** : Les fichiers de police augmenteront la taille de l'application

## 📝 Variantes disponibles

- `.book` : Léger (équivalent à `.light`)
- `.roman` : Normal (équivalent à `.regular`)
- `.medium` : Moyen (équivalent à `.medium`)
- `.heavy` : Gras (équivalent à `.bold`)
- `.black` : Très gras (équivalent à `.black`)

## 🔍 Dépannage

Si les polices ne s'affichent pas :

1. Vérifiez que les fichiers sont bien ajoutés au target
2. Vérifiez que les noms dans `Info.plist` correspondent exactement
3. Vérifiez les logs pour les messages d'avertissement
4. Testez avec `UIFont(name: "AvenirLTStd-Roman", size: 16)` dans le code pour vérifier la disponibilité

