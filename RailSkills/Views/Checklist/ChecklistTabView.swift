//
//  ChecklistTabView.swift
//  RailSkills
//
//  Vue réutilisable pour les onglets de checklist (Suivi, VP, TE)
//

import SwiftUI
import Combine

/// Vue réutilisable pour afficher une checklist selon son type
struct ChecklistTabView: View {
    @ObservedObject var vm: ViewModel
    let checklistType: ChecklistType
    let hSizeClass: UserInterfaceSizeClass?
    
    @State private var expandedCategories: Set<UUID> = []
    @State private var showingAddDriverSheet = false
    @State private var searchText: String = ""
    @State private var cachedSections: [ChecklistSection] = []
    @State private var categoryProgressCache: [UUID: (completed: Int, total: Int)] = [:]
    @State private var selectedCategoryId: UUID? = nil
    @State private var checklistFilter: ChecklistFilter = .all
    @State private var collapsedAllCompact: Bool = true
    @State private var searchDebounceTask: Task<Void, Never>?
    
    /// Checklist actuelle selon le type
    private var currentChecklist: Checklist? {
        vm.checklist(for: checklistType)
    }
    
    /// Indique si un conducteur valide est sélectionné
    private var canInteractWithChecklist: Bool {
        !vm.store.drivers.isEmpty && vm.store.drivers.indices.contains(vm.selectedDriverIndex)
    }
    
    @ViewBuilder
    var body: some View {
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
    
    // MARK: - Sidebar (iPad)
    
    private var sidebarView: some View {
        List(selection: $selectedCategoryId) {
            driverSection
            headerSection
            categoriesSection
        }
        .listStyle(.sidebar)
        .navigationTitle(currentChecklist?.title ?? checklistType.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                toolbarMenu
            }
        }
        .sheet(isPresented: $showingAddDriverSheet) {
            AddDriverSheet(vm: vm)
        }
        .onChange(of: cachedSections) { _, _ in
            if selectedCategoryId == nil, let firstSection = cachedSections.first {
                selectedCategoryId = firstSection.categoryId
            }
        }
        .task { @MainActor in
            updateSectionsCache()
            if selectedCategoryId == nil, let firstSection = cachedSections.first {
                selectedCategoryId = firstSection.categoryId
            }
        }
        .onChange(of: currentChecklist?.title) { _, _ in
            Task { @MainActor in
                updateSectionsCache()
            }
        }
        .onChange(of: currentChecklist?.items.count) { _, _ in
            Task { @MainActor in
                updateSectionsCache()
            }
        }
        .onChange(of: expandedCategories) { _, _ in
            Task { @MainActor in
                updateSectionsCache()
            }
        }
        .onChange(of: vm.store.drivers) { _, _ in
            updateCategoryProgressCache()
        }
        .onReceive(vm.objectWillChange) { _ in
            updateCategoryProgressCache()
        }
    }
    
    // MARK: - Compact View (iPhone)
    
    private var compactMainList: some View {
        ScrollView {
            VStack(spacing: 20) {
                DriversPanelView(vm: vm, onAddDriver: {
                    showingAddDriverSheet = true
                })
                .frame(maxWidth: .infinity)
                
                ProgressHeaderView(
                    progress: progress,
                    checklist: currentChecklist,
                    driver: vm.store.drivers.indices.contains(vm.selectedDriverIndex) ? vm.store.drivers[vm.selectedDriverIndex] : nil
                )
                
                compactChecklistContent
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(Color(uiColor: UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(currentChecklist?.title ?? checklistType.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                toolbarMenu
            }
        }
        .sheet(isPresented: $showingAddDriverSheet) {
            AddDriverSheet(vm: vm)
        }
    }
    
    // MARK: - Detail View (iPad)
    
    @ViewBuilder
    private var detailView: some View {
        if let section = getFilteredSections()?.first(where: { $0.categoryId == selectedCategoryId }) {
            NavigationStack {
                List {
                    searchBarSection
                    filterSection
                    categoryHeaderSection(section)
                    questionsSection(section)
                }
                .navigationTitle(section.categoryTitle)
                .navigationBarTitleDisplayMode(.inline)
            }
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
    
    // MARK: - Compact Checklist Content (iPhone)
    
    private var compactChecklistContent: some View {
        VStack(spacing: 16) {
            if currentChecklist == nil || currentChecklist?.items.isEmpty == true {
                ChecklistImportWelcomeView(vm: vm, checklistType: checklistType)
            } else {
                searchBar
                FilterMenuView(selectedFilter: $checklistFilter) {
                    updateSectionsCache()
                }
                
                if let sections = getFilteredSections(), !sections.isEmpty {
                    ForEach(sections) { section in
                        CategorySectionView(
                            section: section,
                            progress: categoryProgressCache[section.categoryId],
                            isExpanded: isCompactSectionExpanded(section.categoryId),
                            canInteract: canInteractWithChecklist,
                            accentColor: accentColorForCategory(section.categoryId),
                            onToggle: { _ in
                                toggleSectionExpansion(for: section.categoryId)
                            },
                            onItemStateChange: { item, newValue in
                                vm.setState(newValue, for: item, type: checklistType)
                                updateCategoryProgressCache()
                            },
                            getState: { item in
                                vm.state(for: item, type: checklistType)
                            },
                            vm: vm
                        )
                    }
                } else {
                    emptyStateView
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var driverSection: some View {
        Section {
            DriversPanelView(vm: vm, onAddDriver: {
                showingAddDriverSheet = true
            })
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }
    
    private var headerSection: some View {
        Section {
            ProgressHeaderView(
                progress: progress,
                checklist: currentChecklist,
                driver: vm.store.drivers.indices.contains(vm.selectedDriverIndex) ? vm.store.drivers[vm.selectedDriverIndex] : nil
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }
    
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
        }
    }
    
    private var searchBarSection: some View {
        Section {
            searchBar
        }
    }
    
    private var filterSection: some View {
        Section {
            FilterMenuView(selectedFilter: $checklistFilter) {
                updateSectionsCache()
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            .listRowBackground(Color.clear)
        }
        .listSectionSeparator(.hidden)
    }
    
    private func categoryHeaderSection(_ section: ChecklistSection) -> some View {
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
    }
    
    private func questionsSection(_ section: ChecklistSection) -> some View {
        Section {
            let filteredItems = getFilteredItemsForSection(section)
            if filteredItems.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredItems) { item in
                    ChecklistRow(
                        item: item,
                        state: Binding(
                            get: { vm.state(for: item, type: checklistType) },
                            set: { newValue in
                                vm.setState(newValue, for: item, type: checklistType)
                                updateCategoryProgressCache()
                            }
                        ),
                        isExpanded: false,
                        isInteractionEnabled: canInteractWithChecklist,
                        onCategoryToggle: nil,
                        onToggle: { newValue in
                            vm.setState(newValue, for: item, type: checklistType)
                            updateCategoryProgressCache()
                        },
                        vm: vm
                    )
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listSectionSeparator(.hidden)
    }
    
    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField("Rechercher...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .onChange(of: searchText) { _, newValue in
                    searchDebounceTask?.cancel()
                    searchDebounceTask = Task { @MainActor in
                        try? await Task.sleep(nanoseconds: UInt64(AppConstants.Search.debounceDelay * 1_000_000_000))
                        if !Task.isCancelled {
                            updateSectionsCache()
                        }
                    }
                }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(uiColor: UIColor.secondarySystemBackground))
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("Aucune question disponible")
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var toolbarMenu: some View {
        Menu {
            Button {
                showingAddDriverSheet = true
            } label: {
                Label("Ajouter un conducteur", systemImage: "person.badge.plus")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .frame(width: 44, height: 44)
        }
    }
    
    // MARK: - Computed Properties
    
    private var progress: Double {
        vm.progress(for: checklistType)
    }
    
    // MARK: - Helper Methods
    
    private func getFilteredSections() -> [ChecklistSection]? {
        guard currentChecklist != nil else { return nil }
        if cachedSections.isEmpty { return nil }
        
        var sections = cachedSections
        if checklistFilter != .all {
            sections = sections.map { section in
                var filteredSection = section
                filteredSection.items = section.items.filter { item in
                    checklistFilter.matches(state: vm.state(for: item, type: checklistType))
                }
                return filteredSection
            }.filter { !$0.items.isEmpty || checklistFilter == .all }
        }
        return sections
    }
    
    private func updateSectionsCache() {
        guard let cl = currentChecklist else {
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
                if let categoryId = currentCategory {
                    sections.append(ChecklistSection(
                        categoryId: categoryId,
                        categoryTitle: currentCategoryTitle,
                        items: currentItems
                    ))
                }
                currentCategory = item.id
                currentCategoryTitle = item.title
                currentItems = []
            } else {
                let isCategoryExpanded = currentCategory.map { categoryId in
                    if expandedCategories.isEmpty {
                        return true
                    }
                    return expandedCategories.contains(categoryId)
                } ?? true
                
                let shouldShowItem = !searchText.isEmpty || isCategoryExpanded
                
                if shouldShowItem {
                    let matchesSearch = searchText.isEmpty || SearchService.matches(item, searchText: searchText)
                    if matchesSearch {
                        currentItems.append(item)
                    }
                }
            }
        }
        
        if let categoryId = currentCategory {
            sections.append(ChecklistSection(
                categoryId: categoryId,
                categoryTitle: currentCategoryTitle,
                items: currentItems
            ))
        }
        
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
        updateCategoryProgressCache()
    }
    
    private func updateCategoryProgressCache() {
        guard let cl = currentChecklist else {
            categoryProgressCache.removeAll()
            return
        }
        
        categoryProgressCache.removeAll()
        var currentCategory: UUID?
        var currentItems: [ChecklistItem] = []
        
        for item in cl.items {
            if item.isCategory {
                if let categoryId = currentCategory {
                    let total = currentItems.count
                    let completed = currentItems.filter { vm.isChecked($0, type: checklistType) }.count
                    categoryProgressCache[categoryId] = (completed: completed, total: total)
                }
                currentCategory = item.id
                currentItems = []
            } else {
                currentItems.append(item)
            }
        }
        
        if let categoryId = currentCategory {
            let total = currentItems.count
            let completed = currentItems.filter { vm.isChecked($0, type: checklistType) }.count
            categoryProgressCache[categoryId] = (completed: completed, total: total)
        }
    }
    
    private func getFilteredItemsForSection(_ section: ChecklistSection) -> [ChecklistItem] {
        if searchText.isEmpty {
            return section.items
        } else {
            return section.items.filter { item in
                SearchService.matches(item, searchText: searchText)
            }
        }
    }
    
    private func toggleSectionExpansion(for categoryId: UUID) {
        guard hSizeClass == .compact else {
            if expandedCategories.contains(categoryId) {
                expandedCategories.remove(categoryId)
            } else {
                expandedCategories.insert(categoryId)
            }
            updateSectionsCache()
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
    
    private func isCompactSectionExpanded(_ categoryId: UUID) -> Bool {
        guard hSizeClass == .compact else {
            return expandedCategories.contains(categoryId)
        }
        if collapsedAllCompact {
            return false
        }
        return expandedCategories.contains(categoryId)
    }
    
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
}
