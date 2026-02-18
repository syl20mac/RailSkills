//
//  ContentView.swift
//  RailSkills
//
//  Créé par Sylvain GALLON – Application iPad et iPhone pour le suivi des conducteurs sur territoire CFL.
//  SwiftUI • iOS 26+ (iPadOS 26+ exclusif)
//  VERSION OPTIMISÉE COMPLÈTE
//
//  Cette application permet de suivre les conducteurs selon une checklist triennale.
//  Elle offre des fonctionnalités de suivi, d'import/export de données, de génération
//  de rapports PDF et de partage via fichiers JSON.

import SwiftUI
import Combine
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Typealias pour compatibilité
typealias ViewModel = AppViewModel

// MARK: - Vues principales de l'interface utilisateur

/// Vue principale de l'application avec interface adaptative (compacte/large)
struct ContentView: View {
    @StateObject private var vm = ViewModel()
    @StateObject private var cvm = ContentViewModel()
    @EnvironmentObject private var toastManager: ToastNotificationManager
    @AppStorage("selectedDriverID") private var selectedDriverID: String = ""
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.scenePhase) private var scenePhase
    
    // États migrés vers ContentViewModel (cvm)
    // @State private var expandedCategories: Set<UUID> = [] -> cvm.expandedCategories
    // @State private var searchText: String = "" -> cvm.searchText
    // @State private var cachedSections: [ChecklistSection] = [] -> cvm.cachedSections
    // @State private var categoryProgressCache -> cvm.categoryProgressCache
    // @State private var selectedCategoryId -> cvm.selectedCategoryId
    // @State private var selectedTab -> cvm.selectedTab
    // @State private var checklistFilter -> cvm.checklistFilter
    
    @State private var showingAddDriverSheetFromMain = false       // Reste local pour l'instant
    @State private var collapsedAllCompact: Bool = true            // Spécifique vue compacte
    @State private var searchDebounceTask: Task<Void, Never>?      // Potentiellement déplaçable mais gardé pour l'instant
    @State private var showingQuickEvalMode = false                // Affichage du mode évaluation rapide
    @State private var quickEvalType: ChecklistType = .triennale   // Type de checklist pour l'évaluation rapide
    @State private var isSyncing = false
    @State private var showingSyncAlert = false
    @State private var syncAlertMessage = ""

    /// Indique si un conducteur valide est sélectionné pour autoriser les suivis
    private var canInteractWithChecklist: Bool {
        !vm.store.drivers.isEmpty && vm.store.drivers.indices.contains(vm.selectedDriverIndex)
    }

    /// Indique si l’alerte d’interaction doit être affichée (checklist chargée mais aucun conducteur actif)
    private var shouldShowInteractionNotice: Bool {
        guard let checklist = vm.store.checklist, !checklist.items.isEmpty else { return false }
        return !canInteractWithChecklist
    }

    /// Message d’assistance pour guider l’utilisateur vers la création ou la sélection d’un conducteur
    private var interactionNoticeMessage: String {
        if vm.store.drivers.isEmpty {
            return "Ajoutez un conducteur pour commencer le suivi."
        }
        return "Sélectionnez un conducteur pour activer le suivi."
    }

    /// Interface compacte pour petits écrans (iPhone) avec design optimisé
    private var compactMainList: some View {
        ScrollView {
            VStack(spacing: 20) {
                DriversPanelView(vm: vm, onAddDriver: {
                    showingAddDriverSheetFromMain = true
                })
                .frame(maxWidth: CGFloat.infinity)

                ProgressHeaderView(
                    progress: vm.progress,
                    checklist: vm.store.checklist,
                    driver: vm.store.drivers.indices.contains(vm.selectedDriverIndex) ? vm.store.drivers[vm.selectedDriverIndex] : nil
                )

                compactChecklistContent
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color(uiColor: UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(vm.store.checklist?.title ?? "RailSkills")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                toolbarMenu
            }
        }
        .sheet(isPresented: $showingAddDriverSheetFromMain) {
            AddDriverSheet(vm: vm)
        }
    }
    
    /// Sidebar pour iPad: affiche conducteur, progression, et liste des catégories
    private var sidebarView: some View {
        List(selection: $cvm.selectedCategoryId) {
            driverSection
            headerSection
            categoriesSection
        }
        .listStyle(.sidebar)
        .navigationTitle(vm.store.checklist?.title ?? "RailSkills")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                toolbarMenu
            }
        }
        .sheet(isPresented: $showingAddDriverSheetFromMain) {
            AddDriverSheet(vm: vm)
        }
        .onChange(of: cvm.cachedSections) { _, _ in
            // Sélectionner automatiquement la première catégorie quand les sections sont chargées
            if cvm.selectedCategoryId == nil, let firstSection = cvm.cachedSections.first {
                cvm.selectedCategoryId = firstSection.categoryId
            }
        }
    }
    
    /// Section des catégories pour la sidebar
    @ViewBuilder
    private var categoriesSection: some View {
        if !cvm.filteredSections.isEmpty {
            Section("Catégories") {
                ForEach(cvm.filteredSections) { section in
                    NavigationLink(value: section.categoryId) {
                        HStack {
                            Text(section.categoryTitle)
                                .font(.headline)
                            Spacer()
                            if let progress = cvm.categoryProgressCache[section.categoryId] {
                                Text("\(progress.completed)/\(progress.total)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        } else if vm.store.checklist != nil {
            Section {
                Text("Aucune catégorie disponible")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }
    
    /// Panneau de détail pour iPad: affiche les questions de la catégorie sélectionnée
    @ViewBuilder
    private var detailView: some View {
        if vm.store.checklist == nil {
            ChecklistImportWelcomeView(vm: vm)
        } else if let categoryId = cvm.selectedCategoryId,
                  let section = cvm.filteredSections.first(where: { $0.categoryId == categoryId }) {
            
            // Les items sont déjà filtrés dans cvm.filteredSections
            let filteredItems = section.items
            
                 List {
                     // Barre de recherche dans le panneau de détail
                     Section {
                         searchBar
                     }
                     .listSectionSeparator(.hidden)
                     .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
 
                    Section {
                        FilterMenuView(selectedFilter: $cvm.checklistFilter) {
                            cvm.updateFilteredSections()
                        }
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowBackground(Color.clear)
                    }
                    .listSectionSeparator(.hidden)
 
                    if shouldShowInteractionNotice {
                        Section {
                            interactionDisabledNotice
                                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }

                     // En-tête de la catégorie
                     Section {
                         HStack {
                             VStack(alignment: .leading, spacing: 4) {
                                 Text(section.categoryTitle)
                                     .font(.title2)
                                     .fontWeight(.bold)
                                     .foregroundStyle(.primary)
                                 if let progress = cvm.categoryProgressCache[section.categoryId] {
                                     Text("\(progress.completed) sur \(progress.total) complétés")
                                         .font(.subheadline)
                                         .foregroundStyle(.secondary)
                                 }
                             }
                             Spacer()
                             if let progress = cvm.categoryProgressCache[section.categoryId], progress.total > 0 {
                                 let percentage = Double(progress.completed) / Double(progress.total)
                                 CircularProgressView(progress: percentage, size: 48)
                             }
                         }
                         .padding(.vertical, 12)
                         .padding(.horizontal, 4)
                     }
                     .listSectionSeparator(.hidden)
                     .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                
                // Questions de la catégorie (filtrées par la recherche)
                if filteredItems.isEmpty {
                    Section {
                        if cvm.searchText.isEmpty {
                            Text("Aucune question dans cette catégorie")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                                .padding()
        } else {
                            VStack(spacing: 8) {
                                Text("Aucune question trouvée")
                                    .foregroundStyle(.secondary)
                                    .font(.headline)
                                Text("Aucune question ne correspond à '\(cvm.searchText)'")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .padding()
                        }
                    }
            } else {

                         Section {
                             ForEach(filteredItems) { item in
                                 ChecklistRow(
                                     item: item,
                                     state: Binding(
                                         get: { cvm.state(for: item) },
                                         set: { newValue in
                                             cvm.setState(newValue, for: item)
                                             // La mise à jour du cache est gérée par cvm
                                         }
                                     ),
                                     isExpanded: false, // Pas d'expansion dans le détail
                                     isInteractionEnabled: canInteractWithChecklist,
                                     onCategoryToggle: nil, // Pas de toggle de catégorie dans le détail
                                     onToggle: { newValue in
                                         cvm.setState(newValue, for: item)
                                     },
                                     vm: vm
                                 )
                                 .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                 .listRowBackground(Color.clear)
                                 .listRowSeparator(.hidden)
                             }
                         }
                         .listSectionSeparator(.hidden)
                     }
            }
            .navigationTitle(section.categoryTitle)
            .navigationBarTitleDisplayMode(.inline)
                } else {
            VStack(spacing: 16) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                Text("Sélectionnez une catégorie")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text("Choisissez une catégorie dans la liste de gauche pour voir les questions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - List Sections
    
    private var driverSection: some View {
            Section {
                DriversPanelView(vm: vm, onAddDriver: {
                    showingAddDriverSheetFromMain = true
                })
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
        }
            }
            
    private var headerSection: some View {
            Section {
                ProgressHeaderView(
                    progress: vm.progress,
                    checklist: vm.store.checklist,
                    driver: vm.store.drivers.indices.contains(vm.selectedDriverIndex) ? vm.store.drivers[vm.selectedDriverIndex] : nil
                )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
        }
    }
    
    @ViewBuilder
    private var checklistContentSection: some View {
        if vm.store.checklist == nil {
            // Aucune checklist chargée - afficher la vue d'import
            welcomeSection
        } else if let cl = vm.store.checklist, cl.items.isEmpty {
            // Checklist vide - afficher la vue d'import
            welcomeSection
        } else {
            // Checklist présente avec des items - afficher le contenu
            if hSizeClass != .compact {
                searchBarSection
            }
            checklistSections
        }
    }
    
    private var searchBarSection: some View {
            Section {
            searchBar
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField("Rechercher une question ou une note...", text: $cvm.searchText)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .accessibilityLabel("Champ de recherche")
                .accessibilityHint("Tapez pour rechercher une question dans la checklist")
                .onChange(of: cvm.searchText) { _, newValue in
                    // Debounce de la recherche pour éviter les recalculs excessifs
                    searchDebounceTask?.cancel()
                    searchDebounceTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: UInt64(AppConstants.Search.debounceDelay * 1_000_000_000))
                        if !Task.isCancelled {
                            if !newValue.isEmpty {
                                cvm.cachedSections = []
                            }
                            cvm.updateFilteredSections()
                        }
                    }
                }
            if !cvm.searchText.isEmpty {
                Button {
                    withAnimation {
                        cvm.searchText = ""
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Effacer la recherche")
                .accessibilityHint("Double-tapez pour effacer le texte de recherche")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
        )
    }
    
    /// Contenu principal pour l'expérience iPhone (compact)
    @ViewBuilder
    private var compactChecklistContent: some View {
        if vm.store.checklist == nil || vm.store.checklist?.items.isEmpty == true {
            ChecklistImportWelcomeView(vm: vm)
                .frame(maxWidth: CGFloat.infinity)
        } else if !cvm.filteredSections.isEmpty {
            VStack(spacing: 16) {
                if shouldShowInteractionNotice {
                    interactionDisabledNotice
                }
                FilterMenuView(selectedFilter: $cvm.checklistFilter) {
                    cvm.updateFilteredSections()
                }
                LazyVStack(spacing: 16) {
                    ForEach(cvm.filteredSections) { section in
                    let isExpanded = isCompactSectionExpanded(section.categoryId)
                    let progress = cvm.categoryProgressCache[section.categoryId]
                    let accentColor = accentColorForCategory(section.categoryId)
                    
                    CategorySectionView(
                        section: section,
                        progress: progress,
                        isExpanded: isExpanded,
                        canInteract: canInteractWithChecklist,
                        accentColor: accentColor,
                        onToggle: { categoryId in
                            if hSizeClass == .compact {
                                toggleSectionExpansion(for: categoryId)
                            } else {
                                cvm.toggleCategory(categoryId)
                            }
                        },
                                    onItemStateChange: { item, newValue in
                                        cvm.setState(newValue, for: item)
                                    },
                        getState: { item in
                            cvm.state(for: item)
                        },
                        vm: vm
                    )
                    }
                }
            }
        } else if cvm.cachedSections.isEmpty {
            ProgressView("Chargement des sections…")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 60)
        } else {
            VStack(spacing: 8) {
                Text("Aucune question trouvée")
                .font(.headline)
                .foregroundStyle(.primary)
                if !cvm.searchText.isEmpty {
                    Text("Aucun résultat pour \"\(cvm.searchText)\"")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 40)
        }
    }
    
    /// Sections de checklist utilisées dans les listes (expérience iPad)
    @ViewBuilder
    private var checklistSections: some View {
        if !cvm.filteredSections.isEmpty {
            if shouldShowInteractionNotice {
                Section {
                    interactionDisabledNotice
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            ForEach(cvm.filteredSections) { section in
                Section {
                    if section.items.isEmpty {
                        Text("Aucune question dans cette catégorie")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(section.items) { item in
                            ChecklistRow(
                                item: item,
                                state: Binding(
                                    get: { cvm.state(for: item) },
                                    set: { newValue in
                                        cvm.setState(newValue, for: item)
                                    }
                                ),
                                isExpanded: item.isCategory ? cvm.expandedCategories.contains(item.id) : false,
                                isInteractionEnabled: canInteractWithChecklist,
                                onCategoryToggle: item.isCategory ? {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        cvm.toggleCategory(item.id)
                                    }
                                } : nil,
                                onToggle: { newValue in
                                    cvm.setState(newValue, for: item)
                                },
                                vm: vm
                            )
                        }
                    }
                } header: {
                    sectionHeader(for: section)
                }
            }
        } else if vm.store.checklist != nil && !(vm.store.checklist?.items.isEmpty ?? true) {
            EmptyView()
        }
    }
    
    private func sectionHeader(for section: ChecklistSection) -> some View {
                HStack {
            Text(section.categoryTitle)
                        .font(.headline)
                    Spacer()
            if let progress = cvm.categoryProgressCache[section.categoryId] {
                Text("\(progress.completed)/\(progress.total)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
        }
    }
    
    private var welcomeSection: some View {
        Section {
            ChecklistImportWelcomeView(vm: vm)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
        }
    }
    
    private var toolbarMenu: some View {
        Menu {
            Button {
                showingAddDriverSheetFromMain = true
            } label: {
                Label("Ajouter un conducteur", systemImage: "person.badge.plus")
            }
            
            if vm.store.checklist != nil && canInteractWithChecklist {
                Button {
                    showingQuickEvalMode = true
                } label: {
                    Label("Mode évaluation rapide", systemImage: "bolt.fill")
                }
            }
            
            /*
            if vm.store.checklist != nil {
                Button {
                    // Action pour partager
                } label: {
                    Label("Partager", systemImage: "square.and.arrow.up")
                }
            }
            */
            
            Divider()
            
            Button {
                isSyncing = true
                Task {
                    let success = await vm.store.forceDownloadChecklist()
                    isSyncing = false
                    syncAlertMessage = success ? "Synchronisation réussie !" : "Échec de la synchronisation. Vérifiez votre connexion."
                    showingSyncAlert = true
                }
            } label: {
                if isSyncing {
                    Label("Synchronisation en cours...", systemImage: "arrow.triangle.2.circlepath")
                } else {
                    Label("Forcer la synchronisation", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        } label: {
            if isSyncing {
                ProgressView()
                    .frame(width: 44, height: 44)
            } else {
                Image(systemName: "ellipsis.circle")
                    .frame(width: 44, height: 44)
            }
        }
    }
    
    // MARK: - Helpers
    
    /// Retourne les sections filtrées selon le texte de recherche
    /// Cette méthode ne modifie PAS l'état pendant le rendu

    /// Spécifique à l'expérience iPhone : gère l'état plié/déplié d'une section
    private func toggleSectionExpansion(for categoryId: UUID) {
        // Gestion spécifique à l'iPhone : aucune action sur iPad
        guard hSizeClass == .compact else {
            cvm.toggleCategory(categoryId)
            return
        }

        if collapsedAllCompact {
            cvm.expandedCategories = [categoryId]
            collapsedAllCompact = false
        } else if cvm.expandedCategories.contains(categoryId) {
            cvm.expandedCategories.remove(categoryId)
            if cvm.expandedCategories.isEmpty {
                collapsedAllCompact = true
            }
        } else {
            cvm.expandedCategories.insert(categoryId)
        }
        cvm.updateFilteredSections()
    }
    
    // MARK: - Body

    private var mainTabView: some View {
        TabView(selection: $cvm.selectedTab) {
            // Onglet Dashboard (premier onglet)
            AnyView(
                NavigationStack {
                    DashboardView(vm: vm)
                }
            )
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }
            .tag(0)
            
            // Onglet Suivi (Triennale - module principal)
            AnyView(mainContentView)
                .tabItem {
                    Label("Suivi", systemImage: "list.bullet.rectangle")
                }
                .tag(1)
            
            // Onglet VP (Visite Périodique)
            AnyView(ChecklistTabView(vm: vm, checklistType: .vp, hSizeClass: hSizeClass))
                .tabItem {
                    Label("VP", systemImage: "checkmark.circle.fill")
                }
                .tag(2)
            
            // Onglet TE (Triennale Élargie)
            AnyView(ChecklistTabView(vm: vm, checklistType: .te, hSizeClass: hSizeClass))
                .tabItem {
                    Label("TE", systemImage: "checkmark.seal.fill")
                }
                .tag(3)
            
            // Onglet Éditeur de checklist
            AnyView(ChecklistEditorView(vm: vm))
                .tabItem {
                    Label("Éditeur", systemImage: "square.and.pencil")
                }
                .tag(4)
            
            /*
            // Onglet Partage / Export - Masqué temporairement à la demande de l'utilisateur
            AnyView(SharingView(vm: vm))
                .tabItem {
                    Label("Partage", systemImage: "square.and.arrow.up")
                }
                .tag(5)
            */
            
            // Onglet Rapports
            AnyView(ReportsView(vm: vm))
                .tabItem {
                    Label("Rapports", systemImage: "doc.text")
                }
                .tag(6)
            
            // Onglet Réglages
            AnyView(SettingsView(vm: vm))
                .tabItem {
                    Label("Réglages", systemImage: "gear")
                }
                .tag(7)
        }
    }
    
    private var configuredTabView: some View {
        mainTabView
            .task { @MainActor in
                // Injecter le store dans le ContentViewModel
                cvm.configure(with: vm.store)
                cvm.updateFilteredSections()
            }
    }
    
    private var tabViewWithLifecycle: some View {
        configuredTabView
            .onChange(of: vm.store.checklist?.title) { _, _ in
                Task { @MainActor in
                    cvm.updateFilteredSections()
                }
            }
            .onChange(of: vm.store.checklist?.items.count) { _, _ in
                Task { @MainActor in
                    cvm.updateFilteredSections()
                }
            }
            .onChange(of: cvm.expandedCategories) { _, _ in
                Task { @MainActor in
                    cvm.updateFilteredSections()
                }
            }
            .onChange(of: cvm.searchText) { _, newValue in
                searchDebounceTask?.cancel()
                searchDebounceTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(AppConstants.Search.debounceDelay * 1_000_000_000))
                    if !Task.isCancelled {
                        cvm.updateFilteredSections()
                    }
                }
            }
            .onChange(of: vm.selectedDriverIndex) { _, newIndex in
                 cvm.selectedDriverIndex = newIndex
                 cvm.updateFilteredSections()
            }
    }
    
    var body: some View {
        tabViewWithLifecycle
            .onChange(of: scenePhase) { oldPhase, newPhase in
                // Synchroniser automatiquement quand l'app revient en avant-plan pour récupérer les modifications depuis le site web
                if oldPhase != .active && newPhase == .active {
                    Task {
                        // Attendre un peu que l'app soit complètement active
                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
                        _ = try? await vm.store.syncDriversBidirectional()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingQuickEvalMode) {
                QuickEvaluationMode(vm: vm, checklistType: .triennale)
            }
            .overlay(alignment: .topTrailing) {
                // Indicateur de sauvegarde discret
                if vm.store.isSaving {
                    HStack(spacing: 6) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.7)
                        Text("Sauvegarde...")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(uiColor: UIColor.secondarySystemBackground))
                            .shadow(radius: 2)
                    )
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
            }
            .alert(syncAlertMessage, isPresented: $showingSyncAlert) {
                Button("OK", role: .cancel) { }
            }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        if hSizeClass == .compact {
            NavigationStack {
                compactMainList
            }
                } else {
            NavigationSplitView {
                sidebarView
            } detail: {
                detailView
            }
        }
    }
    

}

// MARK: - Extensions et helpers supplémentaires

extension ContentView {


    /// Carte d'information affichée quand aucune interaction n'est possible sur la checklist
    private var interactionDisabledNotice: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.crop.circle.badge.exclam")
                .font(.title2)
                .foregroundStyle(.blue)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Sélection requise")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(interactionNoticeMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if vm.store.drivers.isEmpty {
                    Button {
                        showingAddDriverSheetFromMain = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                            Text("Créer un conducteur")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .accessibilityLabel("Créer un nouveau conducteur")
                    .accessibilityHint("Double-tapez pour ouvrir le formulaire de création de conducteur")
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Sélection requise. \(interactionNoticeMessage)")
    }


    /// Couleur d'accent pour une catégorie selon son ratio
    private func accentColorForCategory(_ categoryId: UUID) -> Color {
        guard let progress = cvm.categoryProgressCache[categoryId], progress.total > 0 else {
            return accentColorForRatio(0)
        }
        let ratio = Double(progress.completed) / Double(progress.total)
        return accentColorForRatio(ratio)
    }

    private func accentColorForRatio(_ ratio: Double) -> Color {
        let clamped = max(0, min(1, ratio))
        return clamped >= 1 ? SNCFColors.menthe : SNCFColors.ceruleen
    }

    private func isCompactSectionExpanded(_ categoryId: UUID) -> Bool {
        guard hSizeClass == .compact else {
            return cvm.expandedCategories.contains(categoryId)
        }
        if collapsedAllCompact {
            return false
        }
        return cvm.expandedCategories.contains(categoryId)
    }

    private func collapseAllCompactCategoriesManual() {
        guard hSizeClass == .compact else { return }
        guard collapsedAllCompact else { return }
        cvm.expandedCategories.removeAll()
        cvm.updateFilteredSections()
    }

    private func expandAllCompactCategoriesManual() {
        guard hSizeClass == .compact else { return }
        collapsedAllCompact = false
        // On conserve les catégories actuellement ouvertes
        cvm.updateFilteredSections()
    }
}

// MARK: - Supporting Views

private struct DriverIndexChangeModifier: ViewModifier {
    @ObservedObject var vm: ViewModel
    @Binding var selectedDriverID: String

    func body(content: Content) -> some View {
        // iOS 18+ : onChange simplifié
        content.onChange(of: vm.selectedDriverIndex) { oldValue, newIndex in
            if vm.store.drivers.indices.contains(newIndex) {
                selectedDriverID = vm.store.drivers[newIndex].id.uuidString
            }
        }
    }
}

