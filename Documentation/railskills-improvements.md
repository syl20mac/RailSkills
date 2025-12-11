# RailSkills - Guide d'Amélioration pour Cursor IA
**Version:** 2.1  
**Date:** Novembre 2024  
**Plateforme:** iOS 16+ / iPadOS 16+  
**Technologies:** SwiftUI, Combine, MVVM, Microsoft Graph API

---

## 📋 TABLE DES MATIÈRES

1. [Contexte du Projet](#contexte-du-projet)
2. [Priorité 1: Synchronisation SharePoint](#priorite-1-synchronisation-sharepoint)
3. [Priorité 2: Performance & UX](#priorite-2-performance--ux)
4. [Priorité 3: Dashboard Enrichi](#priorite-3-dashboard-enrichi)
5. [Priorité 4: Sécurité & Audit](#priorite-4-securite--audit)
6. [Priorité 5: Expérience Utilisateur](#priorite-5-experience-utilisateur)
7. [Priorité 6: Design & Accessibilité](#priorite-6-design--accessibilite)

---

## 🎯 CONTEXTE DU PROJET

### Application
RailSkills est une application iOS/iPadOS native pour la SNCF permettant aux CTT (Cadres Transport Traction) et ARC (Adjoints Référents Conduite) de gérer le suivi triennal réglementaire des conducteurs circulant au Luxembourg.

### Architecture Actuelle
- **Pattern:** MVVM avec SwiftUI + Combine
- **Persistance:** UserDefaults + iCloud Key-Value Store
- **Services:** Store, SharePoint, Export, PDF, Encryption, AuditLogger
- **Navigation:** 5 onglets (Suivi, Éditeur, Partage, Dashboard, Rapports, Réglages)
- **Données:** 46 points de contrôle CFL en 6 catégories

### Stack Technique
```
Swift 5.9+
iOS 16+ / iPadOS 16+
SwiftUI, Combine
Microsoft Graph API (SharePoint)
AES-GCM (chiffrement)
```

---

## 🔥 PRIORITÉ 1: SYNCHRONISATION SHAREPOINT

**Objectif:** Finaliser l'intégration SharePoint pour permettre l'accès PC aux données iPad

### 1.1 Configuration SharePoint Améliorée

**Créer:** `Views/Settings/SharePointSetupView.swift`

**Fonctionnalités:**
- Wizard visuel en 3 étapes (Config Azure AD → Test connexion → Sync active)
- Saisie sécurisée du Client Secret avec validation
- Test de connexion avec feedback détaillé
- Aide contextuelle pour obtenir le Client Secret depuis Azure Portal
- Historique de synchronisation avec statuts

**Points clés:**
```swift
- Configuration guidée avec WizardStep
- Validation en temps réel de la connexion SharePoint
- Stockage sécurisé du Client Secret via SecretManager
- Feedback visuel avec couleurs SNCF (menthe, safran, corail)
- Sheet d'aide avec instructions étape par étape
```

### 1.2 Gestion des Conflits de Synchronisation

**Modifier:** `Services/SharePointSyncService.swift`

**Ajouter les énumérations et structures:**
```swift
enum SyncConflictResolution {
    case useLocal      // Version iPad prioritaire
    case useRemote     // Version SharePoint prioritaire
    case merge         // Fusion intelligente (recommandé)
    case askUser       // Intervention manuelle
}

struct SyncConflict {
    let driverName: String
    let driverId: UUID
    let localVersion: DriverRecord
    let remoteVersion: DriverRecord
    let localModifiedDate: Date
    let remoteModifiedDate: Date
}
```

**Logique de fusion intelligente:**
```
1. Dates d'évaluation: prendre la plus récente
2. Date triennale: conserver la plus ancienne (référence)
3. États des questions: privilégier les plus avancés (2 > 1 > 0)
4. Notes: concaténer si différentes avec séparateur
5. Dates de suivi: prendre les plus récentes
```

**Méthodes à implémenter:**
- `syncWithConflictResolution()` - Sync avec détection de conflits
- `mergeDriverRecords()` - Fusion intelligente de deux versions
- `fetchAllDriversFromSharePoint()` - Récupération complète
- `uploadResolvedDrivers()` - Upload après résolution
- `testFolderAccess()` - Validation de la connexion

### 1.3 UI de Résolution de Conflits

**Créer:** `Views/Sharing/ConflictResolutionView.swift`

**Interface:**
```
┌────────────────────────────────────┐
│ ⚠️ Conflits de synchronisation     │
│ 3 conducteur(s) modifié(s)         │
├────────────────────────────────────┤
│ 👤 Jean Dupont                     │
│ ┌───────────┐  ┌───────────┐      │
│ │   iPad    │  │ SharePoint│      │
│ │ il y a 2h │  │ il y a 1h │ ✓    │
│ └───────────┘  └───────────┘      │
│ ☑️ Fusionner intelligemment (rec.) │
└────────────────────────────────────┘
```

**Composants:**
- `ConflictResolutionView` - Liste des conflits
- `ConflictCardView` - Carte individuelle avec choix
- `versionCard()` - Comparaison visuelle des versions
- Badges de recommandation

### 1.4 Indicateur de Synchronisation

**Créer:** `Views/Components/SyncIndicatorView.swift`

**Affichage compact dans la barre de navigation:**
```
[✓ 2m] - Sync OK il y a 2 minutes
[⟳...] - Synchronisation en cours
[☁️]   - Configuré mais pas encore sync
[⚠️]   - Erreur de synchronisation
```

**Fonctionnalités:**
- Indicateur temps réel de l'état de sync
- Tap pour ouvrir sheet avec détails complets
- Bouton de sync manuelle
- Affichage des erreurs avec messages clairs

---

## ⚡ PRIORITÉ 2: PERFORMANCE & UX

### 2.1 Système de Recherche Optimisé

**Modifier:** `ContentView.swift`

**Remplacer le debounce manuel par Combine:**

```swift
// AVANT (inefficace)
@State private var searchText: String = ""
@State private var searchDebounceTask: Task<Void, Never>?

// APRÈS (optimisé)
@StateObject private var searchDebouncer = SearchDebouncer()

class SearchDebouncer: ObservableObject {
    @Published var searchText: String = ""
    @Published var debouncedText: String = ""
    
    private var cancellable: AnyCancellable?
    
    init(delay: TimeInterval = 0.3) {
        cancellable = $searchText
            .debounce(for: .seconds(delay), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] value in
                self?.debouncedText = value
            }
    }
}
```

**Avantages:**
- Pas de memory leak avec Task
- Meilleure gestion de la mémoire
- Annulation automatique
- Performance améliorée sur filtrage

### 2.2 Cache Intelligent des Sections

**Créer:** `Utilities/SectionCache.swift`

**Système de cache Actor-based:**

```swift
actor SectionCache {
    private var cache: [String: CachedSections] = [:]
    private let cacheLifetime: TimeInterval = 300 // 5 min
    
    struct CachedSections {
        let sections: [ChecklistSection]
        let timestamp: Date
        let searchText: String
        let filter: ChecklistFilter
    }
    
    func get(for key: String, ...) -> [ChecklistSection]?
    func set(_ sections: [ChecklistSection], for key: String, ...)
    func invalidateAll()
    func cleanExpired()
}
```

**Utilisation dans AppViewModel:**
```swift
func getCachedSections(searchText: String, filter: ChecklistFilter) async -> [ChecklistSection] {
    let cacheKey = "\(selectedDriver.id)_\(store.checklist?.title ?? "")"
    
    // Vérifier cache
    if let cached = await SectionCache.get(for: cacheKey, ...) {
        return cached
    }
    
    // Calculer et mettre en cache
    let sections = computeSections(searchText: searchText, filter: filter)
    await SectionCache.set(sections, for: cacheKey, ...)
    
    return sections
}
```

**Impact:**
- Réduction de 70% des recalculs de sections
- Scroll fluide sans lag
- Mémoire optimisée (nettoyage auto)

### 2.3 Animations Fluides

**Améliorer les transitions:**

```swift
// Transitions entre onglets
TabView(selection: $selectedTab) {
    // ... vos onglets
}
.animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)

// Ouverture/fermeture catégories
withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
    expandedCategories.toggle(categoryId)
}

// Apparition des cartes
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))
```

### 2.4 Préchargement Intelligent

**Créer:** `Services/PreloadService.swift`

**Concept:**
- Précharge les données du conducteur suivant en arrière-plan
- Stocke progress, stateMap, notesMap, categoryProgress
- Cache avec expiration automatique (5 min)
- Invalidation sur modification

```swift
@MainActor
class PreloadService: ObservableObject {
    static let shared = PreloadService()
    
    func preloadDriver(_ driver: DriverRecord, checklist: Checklist)
    func getPreloadedData(for driverId: UUID) -> PreloadedDriverData?
    func invalidate(driverId: UUID)
}
```

**Usage:**
```swift
// Dans AppViewModel
func preloadNextDriver() {
    let nextIndex = (selectedDriverIndex + 1) % store.drivers.count
    let nextDriver = store.drivers[nextIndex]
    PreloadService.shared.preloadDriver(nextDriver, checklist: checklist)
}
```

---

## 📊 PRIORITÉ 3: DASHBOARD ENRICHI

### 3.1 Graphiques avec Charts (iOS 16+)

**Créer:** `Views/Dashboard/ProgressChartView.swift`

**Graphique en barres de progression:**

```swift
import Charts

Chart {
    ForEach(drivers) { driver in
        BarMark(
            x: .value("Conducteur", driver.name),
            y: .value("Progression", progressFor(driver))
        )
        .foregroundStyle(colorForProgress(progressFor(driver)))
        .annotation(position: .top) {
            Text("\(Int(progressFor(driver)))%")
                .font(.caption2)
        }
    }
}
.chartYScale(domain: 0...100)
```

**Graphique circulaire de répartition:**

```swift
Chart(stateData) { item in
    SectorMark(
        angle: .value("Count", item.count),
        innerRadius: .ratio(0.5),
        angularInset: 2
    )
    .foregroundStyle(item.color)
}
```

**Couleurs adaptatives:**
```swift
func colorForProgress(_ progress: Double) -> Color {
    switch progress {
    case 80...100: return SNCFColors.menthe    // Vert
    case 50..<80:  return SNCFColors.safran    // Orange
    case 20..<50:  return SNCFColors.corail    // Rouge-orange
    default:       return .gray                // Gris
    }
}
```

### 3.2 Timeline des Évaluations

**Créer:** `Views/Dashboard/EvaluationTimelineView.swift`

**Visualisation chronologique:**

```
┌────────────────────────────────────┐
│ Historique des suivis              │
├────────────────────────────────────┤
│  █        █                        │
│  █   █    █        █               │
│  █   █    █    █   █    █          │
│ Nov  Déc  Jan  Fév  Mar  Avr       │
│  15   8   22   5   18   3          │
└────────────────────────────────────┘
```

**Fonctionnalités:**
- Barres proportionnelles au nombre de questions validées
- Scroll horizontal pour 12 derniers mois
- Tap sur un mois pour voir détails:
  - Questions validées
  - Nombre de suivis effectués
  - Durée moyenne estimée
- Animation de sélection

**Calcul intelligent:**
```swift
var recentEvaluations: [MonthlyEvaluation] {
    // Grouper les dates de suivi par mois
    let grouped = Dictionary(grouping: driver.checklistDates) { _, date in
        Calendar.current.startOfMonth(for: date)
    }
    
    // Calculer stats par mois
    return grouped.map { month, dates in
        MonthlyEvaluation(
            month: month,
            questionsValidated: ...,
            evaluationCount: dates.count,
            progressPercentage: ...,
            averageDuration: "2h30m"
        )
    }
}
```

### 3.3 Suggestions Intelligentes

**Créer:** `Views/Dashboard/SmartSuggestionsView.swift`

**Types de suggestions:**

1. **Échéances critiques** (< 30 jours)
   ```
   ⚠️ Échéance proche
   Le triennal de Jean Dupont expire dans 15 jours
   [Priorité: HAUTE]
   ```

2. **Échéances dépassées**
   ```
   🛑 Échéance dépassée
   Le triennal de Marie Martin a expiré il y a 5 jours
   [Priorité: CRITIQUE]
   ```

3. **Progression bloquée** (< 30% + pas d'éval depuis 30j)
   ```
   ⏰ Suivi à reprendre
   Paul Durant n'a pas été évalué depuis 45 jours (progression: 25%)
   [Priorité: MOYENNE]
   ```

4. **Date triennale manquante**
   ```
   📅 Date triennale manquante
   Définir la date de début du triennal pour Sophie Bernard
   [Priorité: BASSE]
   ```

5. **Catégories non commencées**
   ```
   📝 Catégories non démarrées
   Luc Petit : Signalisation, Matériel roulant
   [Priorité: BASSE]
   ```

6. **Félicitations** (100% complété)
   ```
   ⭐ Suivi terminé !
   Emma Rousseau a validé toutes les questions
   [Priorité: BASSE]
   ```

**Logique de tri:**
```swift
var suggestions: [Suggestion] {
    var results: [Suggestion] = []
    
    // Calcul de toutes les suggestions...
    
    // Tri par priorité puis chronologique
    return results.sorted { lhs, rhs in
        if lhs.priority != rhs.priority {
            return lhs.priority.rawValue > rhs.priority.rawValue
        }
        return true
    }
}
```

---

## 🔒 PRIORITÉ 4: SÉCURITÉ & AUDIT

### 4.1 Chiffrement avec Métadonnées Signées

**Modifier:** `Services/EncryptionService.swift`

**Format du fichier chiffré avec métadonnées:**

```
┌────────────────────────────────────────┐
│ 4 bytes: Longueur métadonnées (UInt32) │
├────────────────────────────────────────┤
│ N bytes: Métadonnées JSON              │
├────────────────────────────────────────┤
│ 32 bytes: Signature HMAC-SHA256        │
├────────────────────────────────────────┤
│ M bytes: Données chiffrées AES-GCM     │
└────────────────────────────────────────┘
```

**Métadonnées incluses:**
```json
{
  "version": "2.1",
  "encrypted_at": "2024-11-24T10:30:00Z",
  "app_version": "2.1.0",
  "exported_by": "CTT_12345",
  "device_id": "iPad-ABC123",
  "checksum": "sha256:..."
}
```

**Méthodes:**
```swift
static func encryptWithMetadata(
    _ data: Data,
    secret: String,
    metadata: [String: String] = [:]
) throws -> Data

static func decryptWithMetadata(
    _ data: Data,
    secret: String
) throws -> (data: Data, metadata: [String: String])
```

**Avantages:**
- Vérification d'intégrité (signature HMAC)
- Traçabilité (qui, quand, d'où)
- Versioning (compatibilité future)
- Détection de corruption/falsification

### 4.2 Audit Log Complet

**Modifier:** `Services/AuditLogger.swift`

**Structure d'une entrée:**
```swift
struct AuditEntry {
    let timestamp: Date
    let userId: String?         // ID SNCF si disponible
    let action: AuditAction     // Type d'action
    let target: String          // Cible (conducteur, fichier, etc.)
    let details: [String: String]
    let ipAddress: String?      // Adresse IP locale
    let deviceId: String        // ID unique de l'appareil
}
```

**Actions auditées:**
```swift
enum AuditAction: String {
    // Cycle de vie app
    case appLaunched = "APP_LAUNCHED"
    case appTerminated = "APP_TERMINATED"
    
    // Gestion conducteurs
    case driverCreated = "DRIVER_CREATED"
    case driverModified = "DRIVER_MODIFIED"
    case driverDeleted = "DRIVER_DELETED"
    case driverImported = "DRIVER_IMPORTED"
    case driverExported = "DRIVER_EXPORTED"
    
    // Évaluations
    case evaluationStarted = "EVALUATION_STARTED"
    case evaluationCompleted = "EVALUATION_COMPLETED"
    case questionValidated = "QUESTION_VALIDATED"
    case noteAdded = "NOTE_ADDED"
    case noteModified = "NOTE_MODIFIED"
    
    // Checklist
    case checklistImported = "CHECKLIST_IMPORTED"
    case checklistExported = "CHECKLIST_EXPORTED"
    case checklistModified = "CHECKLIST_MODIFIED"
    
    // Synchronisation
    case syncToSharePoint = "SYNC_SHAREPOINT"
    case syncToiCloud = "SYNC_ICLOUD"
    case syncConflictResolved = "SYNC_CONFLICT_RESOLVED"
    
    // Rapports
    case reportGenerated = "REPORT_GENERATED"
    case reportExported = "REPORT_EXPORTED"
    
    // Sécurité
    case authenticationSuccess = "AUTH_SUCCESS"
    case authenticationFailure = "AUTH_FAILURE"
    case encryptionKeyGenerated = "ENCRYPTION_KEY_GENERATED"
    case dataDecrypted = "DATA_DECRYPTED"
}
```

**Utilisation:**
```swift
// Exemple 1: Export de conducteur
AuditLogger.shared.log(
    action: .driverExported,
    target: "Driver_\(driver.id)",
    details: [
        "driver_name": driver.name,
        "format": "JSON",
        "encrypted": "true",
        "destination": "SharePoint",
        "file_size": "\(data.count) bytes"
    ],
    userId: currentUserId
)

// Exemple 2: Résolution de conflit
AuditLogger.shared.log(
    action: .syncConflictResolved,
    target: "Driver_\(driver.id)",
    details: [
        "resolution": "merge",
        "local_date": localDate.ISO8601Format(),
        "remote_date": remoteDate.ISO8601Format()
    ]
)
```

**Fonctionnalités:**
```swift
class AuditLogger {
    func log(action: AuditAction, target: String, details: [String: String], userId: String?)
    func exportLog() throws -> Data                    // JSON
    func exportLogAsCSV() -> String                   // CSV pour Excel
    func filter(by action: AuditAction) -> [AuditEntry]
    func filter(from: Date, to: Date) -> [AuditEntry]
    func clear()
}
```

**Limite de taille:**
- Maximum 1000 entrées en mémoire
- Rotation automatique (FIFO)
- Export régulier recommandé

### 4.3 Validation des Données Importées

**Créer:** `Services/ValidationService.swift`

**Règles de validation:**

```swift
func validateDriverImport(_ driver: DriverRecord) throws {
    // 1. Nom obligatoire et non vide
    guard !driver.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        throw ValidationError.invalidDriverName
    }
    
    // 2. Validation des dates
    if let triennialStart = driver.triennialStart {
        let threeYearsAgo = Calendar.current.date(byAdding: .year, value: -3, to: Date())!
        let oneYearFuture = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        
        guard triennialStart >= threeYearsAgo && triennialStart <= oneYearFuture else {
            throw ValidationError.invalidTriennialDate
        }
    }
    
    // 3. États valides uniquement (0-3)
    for (_, states) in driver.checklistStates {
        for (_, state) in states {
            guard (0...3).contains(state) else {
                throw ValidationError.invalidQuestionState(state)
            }
        }
    }
    
    // 4. Sanitization des notes
    var sanitizedNotes: [String: [UUID: String]] = [:]
    for (checklistKey, notesMap) in driver.checklistNotes {
        var cleanNotes: [UUID: String] = [:]
        for (questionId, note) in notesMap {
            // Supprimer caractères dangereux et limiter taille
            let clean = note
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .prefix(10000)
            cleanNotes[questionId] = String(clean)
        }
        sanitizedNotes[checklistKey] = cleanNotes
    }
    
    // 5. Vérifier cohérence des UUIDs
    let allQuestionIds = Set(driver.checklistStates.values.flatMap { $0.keys })
    for uuid in allQuestionIds {
        // Vérifier que l'UUID est valide
        _ = uuid.uuidString
    }
}

enum ValidationError: LocalizedError {
    case invalidDriverName
    case invalidTriennialDate
    case invalidQuestionState(Int)
    case invalidUUID
    case noteTooLong
    case unsafeContent
    
    var errorDescription: String? {
        switch self {
        case .invalidDriverName:
            return "Le nom du conducteur est obligatoire"
        case .invalidTriennialDate:
            return "La date triennale doit être comprise entre il y a 3 ans et dans 1 an"
        case .invalidQuestionState(let state):
            return "État de question invalide: \(state) (doit être entre 0 et 3)"
        case .invalidUUID:
            return "Identifiant UUID invalide"
        case .noteTooLong:
            return "La note dépasse la taille maximale autorisée (10000 caractères)"
        case .unsafeContent:
            return "Contenu potentiellement dangereux détecté"
        }
    }
}
```

---

## 📱 PRIORITÉ 5: EXPÉRIENCE UTILISATEUR

### 5.1 Mode Hors-Ligne Robuste

**Créer:** `Services/OfflineManager.swift`

**Concept:**
- File d'attente des synchronisations échouées
- Retry automatique au retour de connexion
- Indicateur visuel du nombre de syncs en attente
- Persistance de la queue (survit au redémarrage)

```swift
@MainActor
class OfflineManager: ObservableObject {
    @Published var isOnline = true
    @Published var pendingSyncs: [PendingSync] = []
    
    struct PendingSync: Identifiable, Codable {
        let id: UUID
        let type: SyncType
        let data: Data
        let timestamp: Date
        let retryCount: Int
    }
    
    enum SyncType: String, Codable {
        case driverUpdate
        case checklistUpdate
        case evaluation
        case report
    }
    
    func queueSync(_ type: SyncType, data: Data)
    func processPendingSyncs() async
    func clearQueue()
}
```

**Monitoring de connexion:**
```swift
import Network

class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    private let monitor = NWPathMonitor()
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: .global())
    }
}
```

**UI avec badge:**
```swift
TabView {
    SharingView(vm: vm)
        .tabItem {
            Label("Partage", systemImage: "square.and.arrow.up")
        }
        .badge(offlineManager.pendingSyncs.count)
}
```

### 5.2 Raccourcis Clavier iPad

**Ajouter dans ContentView:**

```swift
.commands {
    CommandGroup(after: .newItem) {
        Button("Nouveau conducteur") {
            showingAddDriverSheetFromMain = true
        }
        .keyboardShortcut("n", modifiers: [.command])
        
        Button("Rechercher") {
            // Focus sur barre de recherche
            isSearchFocused = true
        }
        .keyboardShortcut("f", modifiers: [.command])
        
        Button("Exporter") {
            selectedTab = 2 // Onglet Partage
        }
        .keyboardShortcut("e", modifiers: [.command])
        
        Button("Rapport PDF") {
            selectedTab = 4 // Onglet Rapports
        }
        .keyboardShortcut("r", modifiers: [.command])
        
        Button("Réglages") {
            selectedTab = 5
        }
        .keyboardShortcut(",", modifiers: [.command])
    }
    
    CommandGroup(after: .sidebar) {
        Button("Conducteur suivant") {
            selectNextDriver()
        }
        .keyboardShortcut(.rightArrow, modifiers: [.command])
        
        Button("Conducteur précédent") {
            selectPreviousDriver()
        }
        .keyboardShortcut(.leftArrow, modifiers: [.command])
    }
}
```

### 5.3 Widgets iOS 16+

**Créer:** `Widgets/RailSkillsWidget.swift`

**Types de widgets:**

1. **Widget Petit** - Progression globale
   ```
   ┌─────────────┐
   │ RailSkills  │
   │             │
   │     78%     │
   │   ████▒▒    │
   │             │
   │  12/15 OK   │
   └─────────────┘
   ```

2. **Widget Moyen** - Liste des 3 prochaines échéances
   ```
   ┌─────────────────────────┐
   │ Échéances proches       │
   │                         │
   │ 🟢 Jean D.  │  45j      │
   │ 🟠 Marie M. │  15j      │
   │ 🔴 Paul D.  │   3j      │
   └─────────────────────────┘
   ```

3. **Widget Large** - Dashboard complet
   ```
   ┌─────────────────────────────────┐
   │ RailSkills                      │
   │ Progression: 78% │ 15 drivers   │
   ├─────────────────────────────────┤
   │ Échéances                       │
   │ 🟢 Jean D.     45j              │
   │ 🟠 Marie M.    15j              │
   │ 🔴 Paul D.      3j              │
   ├─────────────────────────────────┤
   │ Dernière sync: il y a 2h        │
   └─────────────────────────────────┘
   ```

---

## 🎨 PRIORITÉ 6: DESIGN & ACCESSIBILITÉ

### 6.1 Mode Sombre Optimisé

**Améliorer:** `Utilities/SNCFColors.swift`

```swift
extension SNCFColors {
    // Versions adaptatives pour dark mode
    static var adaptiveCeruleen: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0)
                : UIColor(red: 0.0, green: 0.4, blue: 0.8, alpha: 1.0)
        })
    }
    
    static var adaptiveMenthe: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.4, green: 0.9, blue: 0.6, alpha: 1.0)
                : UIColor(red: 0.0, green: 0.7, blue: 0.4, alpha: 1.0)
        })
    }
    
    // Arrière-plans adaptatifs
    static var cardBackground: Color {
        Color(uiColor: .secondarySystemBackground)
    }
    
    static var surfaceBackground: Color {
        Color(uiColor: .systemBackground)
    }
}
```

**Test des contrastes:**
```swift
// Vérifier que les ratios de contraste respectent WCAG AA
// Text normal: minimum 4.5:1
// Text large: minimum 3:1
// UI components: minimum 3:1
```

### 6.2 Accessibilité VoiceOver

**Améliorer les labels:**

```swift
// ChecklistRow
ChecklistRow(item: item, ...)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(item.title)")
    .accessibilityValue("""
        État: \(stateLabel(for: state)). \
        \(hasNote ? "Note présente" : "Aucune note"). \
        \(hasDate ? "Dernière évaluation: \(dateString)" : "Jamais évalué")
    """)
    .accessibilityHint("Tapez deux fois pour changer l'état, tapez trois fois pour ajouter une note")
    .accessibilityAddTraits(hasNote ? [.button, .hasPopup] : [.button])

// Boutons d'action
Button("Exporter") { ... }
    .accessibilityLabel("Exporter le conducteur")
    .accessibilityHint("Génère un fichier JSON chiffré")

// Indicateurs de progression
ProgressView(value: progress)
    .accessibilityLabel("Progression du suivi")
    .accessibilityValue("\(Int(progress * 100)) pour cent complété")

// Images décoratives
Image(systemName: "checkmark.circle.fill")
    .accessibilityHidden(true) // Pas besoin de lire l'icône
```

### 6.3 Dynamic Type Support

**S'assurer que tous les textes s'adaptent:**

```swift
// Limiter les tailles extrêmes si nécessaire
Text("Titre très long qui pourrait poser problème")
    .font(.headline)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

// Layouts adaptatifs
ViewThatFits {
    HStack { /* Layout horizontal */ }
    VStack { /* Layout vertical pour grandes polices */ }
}

// Espacements proportionnels
.padding(.horizontal, 16)
.padding(.vertical, 12)
// Au lieu de valeurs fixes
```

### 6.4 Tests d'Accessibilité

**Checklist à vérifier:**

```
☑️ Tous les éléments interactifs ont un label
☑️ Les images décoratives sont marquées .accessibilityHidden
☑️ Les boutons ont des hints explicites
☑️ L'ordre de tabulation est logique
☑️ Les contrastes respectent WCAG AA (4.5:1)
☑️ Dynamic Type fonctionne jusqu'à xxxLarge
☑️ VoiceOver peut naviguer dans toute l'app
☑️ Les gestes alternatifs sont disponibles (3 taps, etc.)
☑️ Les animations peuvent être réduites (Reduce Motion)
☑️ Les couleurs ne sont pas la seule indication (icons + text)
```

---

## 📋 RÉSUMÉ DES AMÉLIORATIONS

### Tableau Récapitulatif

| Priorité | Amélioration | Effort | Impact | Fichiers |
|----------|-------------|--------|--------|----------|
| 🔥 **1** | Sync SharePoint complète | 2-3j | ⭐⭐⭐⭐⭐ | SharePointSetupView, SharePointSyncService, ConflictResolutionView, SyncIndicatorView |
| ⚡ **2** | Performance & cache | 1-2j | ⭐⭐⭐⭐ | SearchDebouncer, SectionCache, PreloadService |
| 📊 **3** | Dashboard enrichi | 2j | ⭐⭐⭐⭐ | ProgressChartView, EvaluationTimelineView, SmartSuggestionsView |
| 🔒 **4** | Sécurité renforcée | 1-2j | ⭐⭐⭐⭐⭐ | EncryptionService, AuditLogger, ValidationService |
| 📱 **5** | UX avancée | 2-3j | ⭐⭐⭐ | OfflineManager, NetworkMonitor, Keyboard Shortcuts |
| 🎨 **6** | Design & A11Y | 1j | ⭐⭐⭐ | SNCFColors adaptive, VoiceOver labels, Dynamic Type |

### Plan d'Action (2 semaines)

#### Semaine 1: Fondations
- **Jour 1-2:** SharePoint sync + tests
- **Jour 3:** Gestion des conflits
- **Jour 4:** Optimisations performance
- **Jour 5:** Audit log & sécurité

#### Semaine 2: Polish
- **Jour 1-2:** Dashboard enrichi avec Charts
- **Jour 3:** Mode offline robuste
- **Jour 4:** Accessibilité & dark mode
- **Jour 5:** Tests finaux & documentation

---

## 🚀 INSTRUCTIONS POUR CURSOR IA

### Comment utiliser ce guide

1. **Lecture du contexte**
   - Comprendre l'architecture MVVM actuelle
   - Identifier les services existants
   - Repérer les patterns utilisés (Combine, async/await)

2. **Implémentation par priorité**
   - Commencer par Priorité 1 (SharePoint)
   - Tester chaque fonctionnalité avant de continuer
   - Maintenir la cohérence du code

3. **Respect des conventions**
   - Utiliser les couleurs SNCF (SNCFColors)
   - Suivre le pattern MVVM existant
   - Logger les actions importantes
   - Documenter les fonctions publiques

4. **Tests et validation**
   - Tester sur iPad réel pour les performances
   - Vérifier VoiceOver
   - Tester en mode sombre
   - Valider avec différentes tailles de police

### Patterns de code à respecter

```swift
// MARK: - Organisation
// Grouper le code en sections logiques

// Logging
Logger.info("Message", category: "ComponentName")
Logger.success("Opération réussie", category: "ComponentName")
Logger.error("Erreur: \(error)", category: "ComponentName")

// Async/await pour les opérations réseau
func syncData() async throws {
    let data = try await service.fetch()
    // Process data
}

// Combine pour les publishers
@Published var items: [Item] = []

// Main actor pour UI
@MainActor
class ViewModel: ObservableObject {
    // ...
}
```

### Points d'attention

⚠️ **Ne jamais:**
- Bloquer le thread principal
- Hardcoder les secrets (utiliser SecretManager)
- Ignorer les erreurs de déchiffrement
- Oublier de logger les actions critiques

✅ **Toujours:**
- Utiliser async/await pour le réseau
- Chiffrer les exports sensibles
- Valider les imports
- Tester avec VoiceOver

---

## 📞 SUPPORT

Pour toute question sur l'implémentation :
- Consulter les fichiers existants pour les patterns
- Vérifier les services déjà implémentés
- Maintenir la cohérence avec l'existant
- Documenter les changements majeurs

**Version du guide:** 2.1  
**Dernière mise à jour:** Novembre 2024
