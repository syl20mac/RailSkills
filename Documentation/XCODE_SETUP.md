# Configuration Xcode pour AzureADConfig

## ⚠️ Erreur "Invalid redeclaration of 'AzureADConfig'"

Si vous rencontrez cette erreur, c'est parce que **deux fichiers** déclarent `struct AzureADConfig` :

1. ✅ `Configs/AzureADConfig.swift` — **DOIT être compilé** (contient votre Client Secret)
2. ❌ `Documentation/AzureADConfig.template.txt` — **NE DOIT PAS être compilé** (fichier de référence, situé dans Documentation/)

## 🔧 Solution : Exclure le template du Target Membership

### Étapes dans Xcode :

1. **Ouvrez votre projet** dans Xcode

2. **Vérifiez que le template n'est pas dans le projet** : Le fichier `Documentation/AzureADConfig.template.txt` est dans le dossier `Documentation/` et ne devrait pas être dans le projet Xcode. S'il apparaît dans le navigateur de projet, supprimez-le de Xcode (mais pas du disque).

3. **Ouvrez le File Inspector** :
   - Cliquez sur le panneau de droite (ou appuyez sur ⌥⌘1)
   - Vous verrez la section **Target Membership**

4. **Décochez la cible de votre application** :
   - Décochez la case à côté de votre app (ex: "RailSkills")
   - Le template ne sera plus compilé

5. **Vérifiez que `AzureADConfig.swift` EST bien coché** :
   - Sélectionnez `Configs/AzureADConfig.swift`
   - Dans le File Inspector, vérifiez que votre cible d'app EST cochée

6. **Nettoyez le build** :
   - Product > Clean Build Folder (⇧⌘K)
   - Ou : ⌘K pour nettoyer

7. **Recompilez** :
   - Product > Build (⌘B)

## ✅ Vérification

Après ces étapes, vous devriez avoir :

- ✅ `AzureADConfig.swift` : **COCHÉ** dans Target Membership → Compilé
- ❌ `AzureADConfig.template.txt` : **DÉCOCHÉ** dans Target Membership → Non compilé

## 📝 Note

Le fichier template (`AzureADConfig.template.txt`) est un fichier de **référence uniquement**. Il ne doit jamais être compilé car il déclarerait la même structure que le fichier réel, causant un conflit.

## 🔄 Si le problème persiste

1. Fermez Xcode complètement
2. Supprimez le dossier `DerivedData` :
   ```
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. Rouvrez Xcode
4. Product > Clean Build Folder (⇧⌘K)
5. Product > Build (⌘B)

