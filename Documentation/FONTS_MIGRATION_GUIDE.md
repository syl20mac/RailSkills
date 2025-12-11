# Guide de migration vers AvenirLTStd

## 📝 Vue d'ensemble

Ce guide explique comment remplacer les polices système par AvenirLTStd dans toute l'application.

## 🔄 Correspondances des polices

| Ancien (Système) | Nouveau (AvenirLTStd) |
|-----------------|----------------------|
| `.font(.largeTitle)` | `.font(.avenirLargeTitle)` |
| `.font(.title)` | `.font(.avenirTitle)` |
| `.font(.title2)` | `.font(.avenirTitle2)` |
| `.font(.title3)` | `.font(.avenirTitle3)` |
| `.font(.headline)` | `.font(.avenirHeadline)` |
| `.font(.body)` | `.font(.avenirBody)` |
| `.font(.callout)` | `.font(.avenirCallout)` |
| `.font(.subheadline)` | `.font(.avenirSubheadline)` |
| `.font(.footnote)` | `.font(.avenirFootnote)` |
| `.font(.caption)` | `.font(.avenirCaption)` |
| `.font(.caption2)` | `.font(.avenirCaption2)` |

## 📐 Tailles personnalisées

Pour des tailles personnalisées :

```swift
// Ancien :
.font(.system(size: 18, weight: .bold))

// Nouveau :
.font(.avenir(.heavy, size: 18))
```

## 🎨 Graisses disponibles

- `.book` : Léger (équivalent à `.light`)
- `.roman` : Normal (équivalent à `.regular`)
- `.medium` : Moyen (équivalent à `.medium`)
- `.heavy` : Gras (équivalent à `.bold`)
- `.black` : Très gras (équivalent à `.black`)

## 📄 Exemples de remplacement

### Exemple 1 : Titre avec graisse
```swift
// Avant :
Text("Titre")
    .font(.title2)
    .fontWeight(.bold)

// Après :
Text("Titre")
    .font(.avenirTitle2)
```

### Exemple 2 : Texte avec taille personnalisée
```swift
// Avant :
Text("Texte")
    .font(.system(size: 16, weight: .medium))

// Après :
Text("Texte")
    .font(.avenir(.medium, size: 16))
```

### Exemple 3 : Légende
```swift
// Avant :
Text("Légende")
    .font(.caption)

// Après :
Text("Légende")
    .font(.avenirCaption)
```

## 🔍 Recherche et remplacement

Pour remplacer rapidement toutes les occurrences dans Xcode :

1. Ouvrez "Find and Replace" (⌘+⌥+F)
2. Recherchez : `.font(\.headline)`
3. Remplacez par : `.font(\.avenirHeadline)`
4. Répétez pour chaque type de police

## ⚠️ Notes importantes

1. **Fallback automatique** : Si AvenirLTStd n'est pas disponible, l'application utilisera automatiquement la police système
2. **Compatibilité** : Toutes les tailles et graisses sont compatibles iPhone et iPad
3. **Performance** : Aucun impact sur les performances, les polices sont chargées une seule fois
4. **PDFs** : Les PDFs utilisent déjà AvenirLTStd automatiquement

## 📋 Checklist de migration

- [ ] Ajouter les fichiers de police au projet
- [ ] Vérifier Info.plist
- [ ] Remplacer `.font(.headline)` → `.font(.avenirHeadline)`
- [ ] Remplacer `.font(.title)` → `.font(.avenirTitle)`
- [ ] Remplacer `.font(.body)` → `.font(.avenirBody)`
- [ ] Remplacer `.font(.caption)` → `.font(.avenirCaption)`
- [ ] Remplacer les tailles personnalisées
- [ ] Tester sur iPhone
- [ ] Tester sur iPad
- [ ] Vérifier les PDFs générés

## 🐛 Dépannage

Si les polices ne s'affichent pas :
1. Vérifiez que les fichiers sont dans le target
2. Vérifiez les noms dans Info.plist
3. Consultez les logs pour les avertissements
4. L'application fonctionnera avec le fallback système

