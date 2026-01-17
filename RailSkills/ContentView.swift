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
    @EnvironmentObject private var toastManager: ToastNotificationManager
    @AppStorage("selectedDriverID") private var selectedDriverID: String = ""
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @State private var expandedCategories: Set<UUID> = []           // catégories dépliées
    @State private var showingAddDriverSheetFromMain = false       // affichage de la feuille d'ajout
    @State private var searchText: String = ""                     // texte de recherche pour filtrer
    @State private var cachedSections: [ChecklistSection] = []     // cache des sections pour optimiser le rendu
    @State private var categoryProgressCache: [UUID: (completed: Int, total: Int)] = [:] // cache de progression par catégorie
    @State private var selectedCategoryId: UUID? = nil             // catégorie sélectionnée pour le panneau de détail (iPad)
    @State private var selectedTab: Int = 0                        // Onglet sélectionné (Dashboard par défaut)
    @State private var checklistFilter: ChecklistFilter = .all     // Filtre des questions selon l'état
    @State private var collapsedAllCompact: Bool = true            // Indique si toutes les catégories sont repliées sur iPhone
    @State private var searchDebounceTask: Task<Void, Never>?      // Task pour le debounce de recherche
    @State private var showingQuickEvalMode = false                // Affichage du mode évaluation rapide

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
        List(selection: $selectedCategoryId) {
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
        .onChange(of: cachedSections) { _, _ in
            // Sélectionner automatiquement la première catégorie quand les sections sont chargées
            if selectedCategoryId == nil, let firstSection = cachedSections.first {
                selectedCategoryId = firstSection.categoryId
            }
        }
    }
    
    /// Section des catégories pour la sidebar
    @ViewBuilder
    private var categoriesSection: some View {
        if let sections = getFilteredSections(), !sections.isEmpty {
            Section("Catégories") {
                ForEach(sections) { section in
                    NavigationLink(value: section.categoryId) {
                        HStack {
                            Text(section.categoryTitle)
                                .font(.headline)
                            Spacer()
                            if let progress = categoryProgressCache[section.categoryId] {
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
        } else if let categoryId = selectedCategoryId,
                  let section = getFilteredSections()?.first(where: { $0.categoryId == categoryId }) {
            // Filtrer les items selon la recherche (titre et notes)
            let filteredItems = getFilteredItemsForSection(section)
            
                 List {
                     // Barre de recherche dans le panneau de détail
                     Section {
                         searchBar
                     }
                     .listSectionSeparator(.hidden)
                     .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
 
                    Section {
                        FilterMenuView(selectedFilter: $checklistFilter) {
                            updateSectionsCache()
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
                                 if let progress = categoryProgressCache[section.categoryId] {
                                     Text("\(progress.completed) sur \(progress.total) complétés")
                                         .font(.subheadline)
                                         .foregroundStyle(.secondary)
                                 }
                             }
                             Spacer()
                             if let progress = categoryProgressCache[section.categoryId], progress.total > 0 {
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
                        if searchText.isEmpty {
                            Text("Aucune question dans cette catégorie")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                                .padding()
        } else {
                            VStack(spacing: 8) {
                                Text("Aucune question trouvée")
                                    .foregroundStyle(.secondary)
                                    .font(.headline)
                                Text("Aucune question ne correspond à '\(searchText)'")
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
                                         get: { vm.state(for: item) },
                                         set: { newValue in
                                             vm.setState(newValue, for: item)
                                             updateCategoryProgressCache()
                                         }
                                     ),
                                     isExpanded: false, // Pas d'expansion dans le détail
                                     isInteractionEnabled: canInteractWithChecklist,
                                     onCategoryToggle: nil, // Pas de toggle de catégorie dans le détail
                                     onToggle: { newValue in
                                         vm.setState(newValue, for: item)
                                         updateCategoryProgressCache()
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
            TextField("Rechercher une question ou une note...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .accessibilityLabel("Champ de recherche")
                .accessibilityHint("Tapez pour rechercher une question dans la checklist")
                .onChange(of: searchText) { _, newValue in
                    // Debounce de la recherche pour éviter les recalculs excessifs
                    searchDebounceTask?.cancel()
                    searchDebounceTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: UInt64(AppConstants.Search.debounceDelay * 1_000_000_000))
                        if !Task.isCancelled {
                            if !newValue.isEmpty {
                                cachedSections = []
                            }
                            updateSectionsCache()
                        }
                    }
                }
            if !searchText.isEmpty {
                Button {
                    withAnimation {
                        searchText = ""
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
        } else if let sections = getFilteredSections(), !sections.isEmpty {
            VStack(spacing: 16) {
                if shouldShowInteractionNotice {
                    interactionDisabledNotice
                }
                FilterMenuView(selectedFilter: $checklistFilter) {
                    updateSectionsCache()
                }
                LazyVStack(spacing: 16) {
                    ForEach(sections) { section in
                    let isExpanded = isCompactSectionExpanded(section.categoryId)
                    let progress = categoryProgressCache[section.categoryId]
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
                                toggleCategory(categoryId)
                            }
                        },
                                    onItemStateChange: { item, newValue in
                                        vm.setState(newValue, for: item)
                                        // Mettre à jour uniquement la catégorie affectée
                                        if let categoryId = findCategoryId(for: item) {
                                            updateCategoryProgress(for: categoryId)
                                        } else {
                                            updateCategoryProgressCache()
                                        }
                                    },
                        getState: { item in
                            vm.state(for: item)
                        },
                        vm: vm
                    )
                    }
                }
            }
        } else if cachedSections.isEmpty {
            ProgressView("Chargement des sections…")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 60)
        } else {
            VStack(spacing: 8) {
                Text("Aucune question trouvée")
                    .font(.headline)
                    .foregroundStyle(.primary)
                if !searchText.isEmpty {
                    Text("Aucun résultat pour \"\(searchText)\"")
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
        if let filteredSections = getFilteredSections(), !filteredSections.isEmpty {
            if shouldShowInteractionNotice {
                Section {
                    interactionDisabledNotice
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            ForEach(filteredSections) { section in
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
                                    get: { vm.state(for: item) },
                                    set: { newValue in
                                        vm.setState(newValue, for: item)
                                        // Mettre à jour uniquement la catégorie affectée
                                        if let categoryId = findCategoryId(for: item) {
                                            updateCategoryProgress(for: categoryId)
                                        } else {
                                            updateCategoryProgressCache()
                                        }
                                    }
                                ),
                                isExpanded: item.isCategory ? expandedCategories.contains(item.id) : false,
                                isInteractionEnabled: canInteractWithChecklist,
                                onCategoryToggle: item.isCategory ? {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        toggleCategory(item.id)
                                    }
                                } : nil,
                                onToggle: { newValue in
                                    vm.setState(newValue, for: item)
                                    updateCategoryProgressCache()
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
            if let progress = categoryProgressCache[section.categoryId] {
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
            
            if vm.store.checklist != nil {
                Button {
                    // Action pour partager
                } label: {
                    Label("Partager", systemImage: "square.and.arrow.up")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .frame(width: 44, height: 44)
        }
    }
    
    // MARK: - Helpers
    
    /// Retourne les sections filtrées selon le texte de recherche
    /// Cette méthode ne modifie PAS l'état pendant le rendu
    private func getFilteredSections() -> [ChecklistSection]? {
        guard vm.store.checklist != nil else {
            return nil
        }
        
        // Si le cache est vide, retourner nil pour indiquer qu'on attend le chargement
        // Le cache sera rempli dans une tâche asynchrone
        if cachedSections.isEmpty {
            return nil
        }
        
        var sections = cachedSections
        if checklistFilter != ChecklistFilter.all {
            sections = sections.map { section in
                var filteredSection = section
                filteredSection.items = section.items.filter { item in
                    checklistFilter.matches(state: vm.state(for: item))
                }
                return filteredSection
            }.filter { !$0.items.isEmpty || checklistFilter == ChecklistFilter.all }
        }
        return sections
            }
    
    /// Recalcule et met à jour le cache des sections
    /// Cette méthode peut être appelée de manière asynchrone
    private func updateSectionsCache() {
        guard let cl = vm.store.checklist else {
            cachedSections = []
            return
        }
        
        var sections: [ChecklistSection] = []
        var currentCategory: UUID?
        var currentItems: [ChecklistItem] = []
        var currentCategoryTitle = ""
        var hasCategories = false
        
        for item in cl.items {
            if item.isCategory {
                hasCategories = true
                // Sauvegarder la section précédente
                if let categoryId = currentCategory {
                    sections.append(ChecklistSection(
                        categoryId: categoryId,
                        categoryTitle: currentCategoryTitle,
                        items: currentItems
                    ))
                }
                // Nouvelle catégorie
                currentCategory = item.id
                currentCategoryTitle = item.title
                currentItems = []
            } else {
                // Si on recherche, montrer tous les résultats qui correspondent
                // Sinon, montrer seulement les items des catégories dépliées
                // expandedCategories contient les UUID des catégories dépliées
                // Par défaut (quand le Set est vide), toutes les catégories sont dépliées
                let isCategoryExpanded = currentCategory.map { categoryId in
                    // Si expandedCategories est vide, toutes les catégories sont dépliées
                    if expandedCategories.isEmpty {
                        return true
                    }
                    // Sinon, vérifier si la catégorie est dans le Set
                    return expandedCategories.contains(categoryId)
                } ?? true
                
                // Toujours montrer les items si on recherche, sinon seulement si la catégorie est dépliée
                let shouldShowItem = !searchText.isEmpty || isCategoryExpanded
                
                // Vérifier le filtre de recherche (recherche dans le titre ET les notes)
                if shouldShowItem {
                    let matchesSearch = searchText.isEmpty || SearchService.matches(item, searchText: searchText)
                    
                    if matchesSearch {
                        currentItems.append(item)
                    }
                }
            }
        }
        
        // Ajouter la dernière section
        if let categoryId = currentCategory {
            sections.append(ChecklistSection(
                categoryId: categoryId,
                categoryTitle: currentCategoryTitle,
                items: currentItems
            ))
        }
        
        // Si aucune catégorie n'existe, créer une section par défaut avec toutes les questions
        if !hasCategories && !cl.items.isEmpty {
            let allQuestions = cl.items.filter { !$0.isCategory }
            if !allQuestions.isEmpty {
                let defaultSection = ChecklistSection(
                    categoryId: UUID(),
                    categoryTitle: "Questions",
                    items: allQuestions
                )
                sections.append(defaultSection)
            }
        }
        
        cachedSections = sections
        
        // Calculer la progression par catégorie
        categoryProgressCache.removeAll()
        for section in sections {
            let total = section.items.count
            let completed = section.items.filter { vm.isChecked($0) }.count
            categoryProgressCache[section.categoryId] = (completed: completed, total: total)
        }
    }
    
    /// Bascule l'état d'expansion d'une catégorie
    private func toggleCategory(_ categoryId: UUID) {
        if expandedCategories.contains(categoryId) {
            expandedCategories.remove(categoryId)
        } else {
            expandedCategories.insert(categoryId)
        }
        // Le cache sera recalculé automatiquement via onChange(of: expandedCategories)
    }

    /// Spécifique à l'expérience iPhone : gère l'état plié/déplié d'une section
    private func toggleSectionExpansion(for categoryId: UUID) {
        // Gestion spécifique à l'iPhone : aucune action sur iPad
        guard hSizeClass == .compact else {
            toggleCategory(categoryId)
            return
        }

        if collapsedAllCompact {
            expandedCategories = [categoryId]
            collapsedAllCompact = false
        } else if expandedCategories.contains(categoryId) {
            expandedCategories.remove(categoryId)
            if expandedCategories.isEmpty {
                collapsedAllCompact = true
            }
        } else {
            expandedCategories.insert(categoryId)
        }
        updateSectionsCache()
    }
    
    /// Trouve la catégorie d'un item dans la checklist
    /// - Parameter item: L'item dont on cherche la catégorie
    /// - Returns: L'UUID de la catégorie, ou nil si pas de catégorie
    private func findCategoryId(for item: ChecklistItem) -> UUID? {
        guard let cl = vm.store.checklist else { return nil }
        
        var currentCategory: UUID?
        for checklistItem in cl.items {
            if checklistItem.isCategory {
                currentCategory = checklistItem.id
            } else if checklistItem.id == item.id {
                return currentCategory
            }
        }
        return nil
    }
    
    /// Met à jour le cache de progression pour une catégorie spécifique (optimisation incrémentale)
    /// - Parameter categoryId: L'UUID de la catégorie à mettre à jour
    private func updateCategoryProgress(for categoryId: UUID) {
        guard let cl = vm.store.checklist else { return }
        
        // Trouver les questions de cette catégorie
        var categoryItems: [ChecklistItem] = []
        var inTargetCategory = false
        
        for item in cl.items {
            if item.isCategory && item.id == categoryId {
                inTargetCategory = true
                continue
            }
            if item.isCategory && inTargetCategory {
                break // Fin de la catégorie cible
            }
            if inTargetCategory && !item.isCategory {
                categoryItems.append(item)
            }
        }
        
        let total = categoryItems.count
        let completed = categoryItems.filter { vm.isChecked($0) }.count
        categoryProgressCache[categoryId] = (completed: completed, total: total)
    }
    
    /// Met à jour le cache de progression pour toutes les catégories
    /// Calcule la progression en utilisant la checklist complète (sans filtres de recherche/expansion)
    /// Utilise updateCategoryProgress pour chaque catégorie individuellement
    private func updateCategoryProgressCache() {
        guard let cl = vm.store.checklist else {
            categoryProgressCache.removeAll()
            return
        }
        
        // Si on a déjà des sections en cache, mettre à jour uniquement les catégories existantes
        if !cachedSections.isEmpty {
            for section in cachedSections {
                updateCategoryProgress(for: section.categoryId)
            }
            return
        }
        
        // Sinon, recalculer tout (première fois)
        categoryProgressCache.removeAll()
        
        var currentCategory: UUID?
        var currentItems: [ChecklistItem] = []
        var hasCategories = false
        
        // Parcourir toutes les questions de la checklist (sans filtres)
        for item in cl.items {
            if item.isCategory {
                hasCategories = true
                // Sauvegarder la progression de la catégorie précédente
                if let categoryId = currentCategory {
                    let total = currentItems.count
                    let completed = currentItems.filter { vm.isChecked($0) }.count
                    categoryProgressCache[categoryId] = (completed: completed, total: total)
                }
                // Nouvelle catégorie
                currentCategory = item.id
                currentItems = []
            } else {
                // Ajouter toutes les questions à la catégorie courante (pas de filtre)
                currentItems.append(item)
            }
        }
        
        // Ajouter la progression de la dernière catégorie
        if let categoryId = currentCategory {
            let total = currentItems.count
            let completed = currentItems.filter { vm.isChecked($0) }.count
            categoryProgressCache[categoryId] = (completed: completed, total: total)
        }
        
        // Si aucune catégorie n'existe, créer une progression pour toutes les questions
        if !hasCategories && !cl.items.isEmpty {
            let allQuestions = cl.items.filter { !$0.isCategory }
            if !allQuestions.isEmpty, let firstSection = cachedSections.first {
                let total = allQuestions.count
                let completed = allQuestions.filter { vm.isChecked($0) }.count
                categoryProgressCache[firstSection.categoryId] = (completed: completed, total: total)
            }
        }
    }
    
    // MARK: - Body

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
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
            
            // Onglet Partage / Export
            AnyView(SharingView(vm: vm))
                .tabItem {
                    Label("Partage", systemImage: "square.and.arrow.up")
                }
                .tag(5)
            
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
                updateSectionsCache()
                selectFirstCategoryIfNeeded()
                collapseAllCategoriesIfNeeded()
            }
    }
    
    private var tabViewWithLifecycle: some View {
        configuredTabView
            .onChange(of: vm.store.checklist?.title) { _, _ in
                Task { @MainActor in
                    updateSectionsCache()
                    selectFirstCategoryIfNeeded()
                    collapseAllCategoriesIfNeeded()
                }
            }
            .onChange(of: vm.store.checklist?.items.count) { _, _ in
                Task { @MainActor in
                    updateSectionsCache()
                    collapseAllCategoriesIfNeeded()
                }
            }
            .onChange(of: expandedCategories) { _, _ in
                Task { @MainActor in
                    updateSectionsCache()
                }
            }
            .onChange(of: searchText) { _, newValue in
                searchDebounceTask?.cancel()
                searchDebounceTask = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(AppConstants.Search.debounceDelay * 1_000_000_000))
                    if !Task.isCancelled {
                        updateSectionsCache()
                    }
                }
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
    
    /// Sélectionne automatiquement la première catégorie si nécessaire (iPad)
    private func selectFirstCategoryIfNeeded() {
        guard hSizeClass != .compact, selectedCategoryId == nil else { return }
        if let firstSection = cachedSections.first {
            selectedCategoryId = firstSection.categoryId
        }
    }

    /// Mode compact : replie toutes les catégories par défaut
    private func collapseAllCategoriesIfNeeded() {
        guard hSizeClass == .compact else { return }
        guard collapsedAllCompact else { return }
        expandedCategories.removeAll()
        updateSectionsCache()
    }

    private func expandAllCategoriesIfNeeded() {
        guard hSizeClass == .compact else { return }
        collapsedAllCompact = false
        // On conserve les catégories actuellement ouvertes
        updateSectionsCache()
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


    /// Filtre les items d'une section selon le texte de recherche (titre et notes)
    /// Utilise SearchService pour une recherche optimisée
    private func getFilteredItemsForSection(_ section: ChecklistSection) -> [ChecklistItem] {
        if searchText.isEmpty {
            return section.items
        } else {
            return section.items.filter { item in
                SearchService.matches(item, searchText: searchText)
            }
        }
    }
    
    /// Couleur d'accent pour une catégorie selon son ratio
    private func accentColorForCategory(_ categoryId: UUID) -> Color {
        guard let progress = categoryProgressCache[categoryId], progress.total > 0 else {
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
            return expandedCategories.contains(categoryId)
        }
        if collapsedAllCompact {
            return false
        }
        return expandedCategories.contains(categoryId)
    }

    private func collapseAllCompactCategoriesManual() { collapseAllCategoriesIfNeeded() }
    private func expandAllCompactCategoriesManual() { expandAllCategoriesIfNeeded() }
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

