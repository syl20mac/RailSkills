//
//  ChecklistEditorView.swift
//  RailSkills
//
//  Vue d'édition de la checklist (ajout, modification, suppression de catégories et questions)
//

import SwiftUI
import UniformTypeIdentifiers

/// Vue d'édition de la checklist
struct ChecklistEditorView: View {
    @ObservedObject var vm: ViewModel
    @State private var editMode: EditMode = .inactive
    @State private var selectedIndexForAction: Int?
    @State private var showingActionSheet = false
    @State private var showingFileImporter = false
    @State private var importSuccessMessage: String?
    @State private var importErrorMessage: String?
    @State private var showingRemoveChecklistConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var itemToDelete: (index: Int, item: ChecklistItem)?
    @State private var offsetsToDelete: IndexSet?
    @State private var showingAddDriverSheet = false
    @State private var showingDriverImporter = false
    @State private var driverImportResults: [ImportResult] = []
    @State private var pendingMergeDriver: DriverRecord?
    @State private var pendingMergeIndex: Int = 0
    @State private var showingDriverMergeDialog = false
    @State private var driverImportSuccessMessage: String?
    @State private var driverImportErrorMessage: String?
    @State private var showingCategorySelector = false
    @State private var showingCategoryCreator = false
    @State private var pendingQuestionAction: (() -> Void)?
    @State private var selectedTab: Int = 0
    @AppStorage("didForceChecklistReset") private var didForceChecklistReset = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Sélecteur de type de checklist
            Picker("Type de checklist", selection: Binding(
                get: { vm.store.selectedChecklistType },
                set: { vm.store.selectedChecklistType = $0 }
            )) {
                ForEach(ChecklistType.allCases, id: \.self) { type in
                    Text(type.displayTitle).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            
            // Contenu principal
            if vm.store.checklist == nil || vm.store.checklist?.items.isEmpty == true {
                NavigationStack {
                    ChecklistImportWelcomeView(vm: vm, checklistType: vm.store.selectedChecklistType)
                }
            } else {
                TabView(selection: $selectedTab) {
                    // Onglet 1 : Édition des questions et catégories
                    checklistEditorTab
                        .tabItem {
                            Label("Questions", systemImage: "list.bullet.rectangle")
                        }
                        .tag(0)
                    
                    // Onglet 2 : Gestion des conducteurs
                    driversManagementTab
                        .tabItem {
                            Label("Conducteurs", systemImage: "person.2.fill")
                        }
                        .tag(1)
                }
            }
        }
        .task {
            if !didForceChecklistReset {
                await vm.store.resetChecklistsPreservingPersonalItems()
                didForceChecklistReset = true
            }
        }
    }
    
    // MARK: - Onglet Édition Checklist
    
    private var checklistEditorTab: some View {
        NavigationStack {
            List {
                Section {
                    if let checklist = vm.store.checklist, !checklist.items.isEmpty {
                        let enumeratedItems = Array(checklist.items.enumerated())
                        ForEach(enumeratedItems, id: \.element.id) { entry in
                            let isReadOnly = vm.store.isItemReadOnly(entry.element)
                            editorRow(for: entry.element, at: entry.offset, isReadOnly: isReadOnly)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    if !isReadOnly {
                                        Button(role: .destructive) {
                                            prepareDeletion(at: entry.offset)
                                        } label: {
                                            Label("Supprimer", systemImage: "trash")
                                        }
                                    }
                                }
                        }
                        .moveDisabled(true) // Désactivation explicite du déplacement des questions et catégories
                    } else {
                        // iOS 18+ : ContentUnavailableView directement disponible
                        ContentUnavailableView {
                            Label("Aucun élément", systemImage: "list.bullet")
                        } description: {
                            Text("Ajoutez des catégories et des questions pour commencer.")
                        }
                    }
                } header: {
                    HStack {
                        Text("Questions et catégories")
                        Spacer()
                        if let count = vm.store.checklist?.items.count, count > 0 {
                            Text("\(count) éléments")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Éditeur")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation {
                            editMode = editMode == .active ? .inactive : .active
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: editMode == .active ? "checkmark.circle.fill" : "trash")
                                .font(.subheadline)
                            Text(editMode == .active ? "Terminé" : "Mode suppression")
                                .font(.subheadline)
                        }
                        .foregroundStyle(editMode == .active ? SNCFColors.menthe : SNCFColors.corail)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingCategoryCreator = true
                        } label: {
                            Label("Ajouter une catégorie", systemImage: "folder.badge.plus")
                        }
                        
                        Button {
                            showCategorySelectorForQuestion()
                        } label: {
                            Label("Ajouter une question", systemImage: "plus.square")
                        }
                        
                        Divider()
                        
                        Button {
                            showingFileImporter = true
                        } label: {
                            Label("Importer depuis un fichier", systemImage: "doc.badge.plus")
                        }
                        
                        Divider()
                        
                        #if DEBUG
                        Button(role: .destructive) {
                            showingRemoveChecklistConfirmation = true
                        } label: {
                            Label("Supprimer la checklist", systemImage: "trash")
                        }
                        #endif
                        
                    } label: {
                        Label("Ajouter", systemImage: "plus.circle.fill")
                    }
                }
            }
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [UTType.json, UTType.plainText, UTType.text],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        guard url.startAccessingSecurityScopedResource() else {
                            importErrorMessage = "Impossible d'accéder au fichier. Assurez-vous que le fichier est dans l'application Fichiers (iCloud Drive ou sur l'appareil) et réessayez."
                            Logger.error("Impossible d'accéder au fichier: \(url.path)", category: "ChecklistEditor")
                            return
                        }
                        
                        defer {
                            url.stopAccessingSecurityScopedResource()
                        }
                        
                        do {
                            try vm.importTextFile(url: url)
                            importSuccessMessage = "Checklist importée avec succès !"
                            Logger.success("Checklist importée: \(url.lastPathComponent)", category: "ChecklistEditor")
                        } catch {
                            importErrorMessage = "Erreur lors de l'import : \(error.localizedDescription)"
                            Logger.error("Erreur d'import: \(error.localizedDescription)", category: "ChecklistEditor")
                        }
                    }
                case .failure(let error):
                    importErrorMessage = "Erreur lors de la sélection du fichier : \(error.localizedDescription)"
                    Logger.error("Erreur de sélection de fichier: \(error.localizedDescription)", category: "ChecklistEditor")
                }
            }
            .sheet(isPresented: $showingCategorySelector) {
                CategorySelectorView(
                    checklist: vm.store.checklist,
                    onSelect: { categoryIndex, questionText in
                        // Toujours ajouter dans la catégorie sélectionnée
                        addQuestion(with: questionText, in: categoryIndex)
                        showingCategorySelector = false
                    },
                    onCancel: {
                        showingCategorySelector = false
                    }
                )
            }
            .sheet(isPresented: $showingCategoryCreator) {
                CategoryCreatorView(
                    onSave: { categoryName in
                        addCategory(with: categoryName)
                        showingCategoryCreator = false
                    },
                    onCancel: {
                        showingCategoryCreator = false
                    }
                )
            }
            .alert("Import réussi", isPresented: Binding(get: { importSuccessMessage != nil }, set: { if !$0 { importSuccessMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importSuccessMessage ?? "")
            }
            .alert("Erreur d'import", isPresented: Binding(get: { importErrorMessage != nil }, set: { if !$0 { importErrorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importErrorMessage ?? "")
            }
            .alert("Supprimer la checklist", isPresented: $showingRemoveChecklistConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    vm.removeChecklist()
                    importSuccessMessage = "Checklist supprimée. Vous pouvez maintenant importer une nouvelle checklist."
                    Logger.warning("Checklist supprimée par l'utilisateur", category: "ChecklistEditor")
                }
            } message: {
                Text("Cette action supprimera la checklist actuelle. Les données des conducteurs seront conservées. Vous pourrez ensuite importer une nouvelle checklist.")
            }
            .alert("Confirmer la suppression", isPresented: $showingDeleteConfirmation) {
                Button("Annuler", role: .cancel) {
                    itemToDelete = nil
                    offsetsToDelete = nil
                }
                Button("Supprimer", role: .destructive) {
                    if let offsets = offsetsToDelete {
                        deleteItems(at: offsets)
                        offsetsToDelete = nil
                    } else if let toDelete = itemToDelete {
                        deleteItem(at: toDelete.index, item: toDelete.item)
                    }
                    itemToDelete = nil
                    
                    if editMode == .active {
                        editMode = .inactive
                    }
                }
            } message: {
                if let offsets = offsetsToDelete, offsets.count > 1 {
                    return Text("Voulez-vous supprimer \(offsets.count) élément(s) ? Cette action est irréversible.")
                }
                
                if let toDelete = itemToDelete {
                    if toDelete.item.isCategory {
                        let questionCount = countQuestionsInCategory(at: toDelete.index)
                        if questionCount > 0 {
                            return Text("Voulez-vous supprimer la catégorie '\(toDelete.item.title)' et ses \(questionCount) question(s) ? Cette action est irréversible.")
                        } else {
                            return Text("Voulez-vous supprimer la catégorie '\(toDelete.item.title)' ? Cette action est irréversible.")
                        }
                    } else {
                        return Text("Voulez-vous supprimer la question '\(toDelete.item.title)' ? Cette action est irréversible.")
                    }
                }
                return Text("Voulez-vous supprimer cet élément ? Cette action est irréversible.")
            }
        }
    }
    
    // MARK: - Onglet Gestion Conducteurs
    
    private var driversManagementTab: some View {
        NavigationStack {
            DriversManagerView(vm: vm)
                .navigationTitle("Conducteurs")
                .navigationBarTitleDisplayMode(.inline)
        }
        .fileImporter(
            isPresented: $showingDriverImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleDriverFileImport(result: result)
        }
        .sheet(isPresented: $showingAddDriverSheet) {
            AddDriverSheet(vm: vm)
        }
        .alert("Import conducteurs réussi", isPresented: Binding(get: { driverImportSuccessMessage != nil }, set: { if !$0 { driverImportSuccessMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(driverImportSuccessMessage ?? "")
        }
        .alert("Erreur d'import des conducteurs", isPresented: Binding(get: { driverImportErrorMessage != nil }, set: { if !$0 { driverImportErrorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(driverImportErrorMessage ?? "")
        }
        .alert("Conducteur existant", isPresented: $showingDriverMergeDialog) {
            ForEach(MergeStrategy.allCases, id: \.self) { strategy in
                Button(strategy.title) {
                    handleDriverMerge(strategy: strategy)
                }
            }
            Button("Annuler", role: .cancel) {
                pendingMergeDriver = nil
                driverImportResults = []
                showingDriverMergeDialog = false
            }
        } message: {
            if let driver = pendingMergeDriver {
                Text("Le conducteur '\(driver.name)' existe déjà. Choisissez une stratégie de fusion :")
            } else {
                Text("Le conducteur existe déjà. Choisissez une stratégie de fusion :")
            }
        }
    }
    
    
    // MARK: - Helper Methods
    
    private func addCategory() {
        var new = ChecklistItem(title: "Nouvelle catégorie", isCategory: true)
        new.readOnly = false
        vm.store.checklist?.items.append(new)
        vm.store.registerPersonalChecklistItem(new.id)
        Logger.info("Catégorie ajoutée", category: "ChecklistEditor")
    }
    
    /// Ajoute une catégorie avec un nom personnalisé
    private func addCategory(with name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let categoryName = trimmedName.isEmpty ? "Nouvelle catégorie" : trimmedName
        var new = ChecklistItem(title: categoryName, isCategory: true)
        new.readOnly = false
        vm.store.checklist?.items.append(new)
        vm.store.registerPersonalChecklistItem(new.id)
        Logger.info("Catégorie ajoutée avec nom: \(categoryName)", category: "ChecklistEditor")
    }
    
    private func addQuestion() {
        var new = ChecklistItem(title: "Nouvelle question", isCategory: false)
        new.readOnly = false
        vm.store.checklist?.items.append(new)
        vm.store.registerPersonalChecklistItem(new.id)
        Logger.info("Question ajoutée", category: "ChecklistEditor")
    }
    
    /// Ajoute une question avec un texte personnalisé à la fin de la checklist
    private func addQuestion(with text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let questionText = trimmedText.isEmpty ? "Nouvelle question" : trimmedText
        var new = ChecklistItem(title: questionText, isCategory: false)
        new.readOnly = false
        vm.store.checklist?.items.append(new)
        vm.store.registerPersonalChecklistItem(new.id)
        Logger.info("Question ajoutée avec texte: \(questionText)", category: "ChecklistEditor")
    }
    
    /// Ajoute une question dans une catégorie spécifique
    private func addQuestion(in categoryIndex: Int) {
        guard var items = vm.store.checklist?.items,
              items.indices.contains(categoryIndex),
              items[categoryIndex].isCategory else {
            // Si la catégorie n'existe pas, ajouter à la fin
            addQuestion()
            return
        }
        
        var new = ChecklistItem(title: "Nouvelle question", isCategory: false)
        new.readOnly = false
        
        // Trouver la position après la catégorie
        var insertIndex = categoryIndex + 1
        
        // Chercher la fin de la catégorie (jusqu'à la prochaine catégorie ou la fin de la liste)
        while insertIndex < items.count {
            if items[insertIndex].isCategory {
                // On a trouvé la prochaine catégorie, insérer juste avant
                break
            }
            insertIndex += 1
        }
        
        // Insérer la nouvelle question à la position trouvée
        items.insert(new, at: insertIndex)
        vm.store.checklist?.items = items
        vm.store.registerPersonalChecklistItem(new.id)
        Logger.info("Question ajoutée dans la catégorie à l'index \(categoryIndex), position finale: \(insertIndex)", category: "ChecklistEditor")
    }
    
    /// Ajoute une question avec un texte personnalisé dans une catégorie spécifique
    private func addQuestion(with text: String, in categoryIndex: Int) {
        guard var items = vm.store.checklist?.items,
              items.indices.contains(categoryIndex),
              items[categoryIndex].isCategory else {
            // Si la catégorie n'existe pas, ajouter à la fin
            addQuestion(with: text)
            return
        }
        
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let questionText = trimmedText.isEmpty ? "Nouvelle question" : trimmedText
        var new = ChecklistItem(title: questionText, isCategory: false)
        new.readOnly = false
        
        // Trouver la position après la catégorie
        var insertIndex = categoryIndex + 1
        
        // Chercher la fin de la catégorie (jusqu'à la prochaine catégorie ou la fin de la liste)
        while insertIndex < items.count {
            if items[insertIndex].isCategory {
                // On a trouvé la prochaine catégorie, insérer juste avant
                break
            }
            insertIndex += 1
        }
        
        // Insérer la nouvelle question à la position trouvée
        items.insert(new, at: insertIndex)
        vm.store.checklist?.items = items
        vm.store.registerPersonalChecklistItem(new.id)
        Logger.info("Question ajoutée avec texte '\(questionText)' dans la catégorie à l'index \(categoryIndex), position finale: \(insertIndex)", category: "ChecklistEditor")
    }
    
    /// Affiche le sélecteur de catégorie pour ajouter une question
    private func showCategorySelectorForQuestion() {
        pendingQuestionAction = {
            // Action sera définie dans la sheet
        }
        showingCategorySelector = true
    }
    
    private func addQuestionAfterIndex(_ index: Int) {
        var new = ChecklistItem(title: "Nouvelle question", isCategory: false)
        new.readOnly = false
        vm.store.checklist?.items.insert(new, at: index + 1)
        vm.store.registerPersonalChecklistItem(new.id)
        Logger.info("Question ajoutée après l'index \(index)", category: "ChecklistEditor")
    }
    
    private func addCategoryAfterIndex(_ index: Int) {
        var new = ChecklistItem(title: "Nouvelle catégorie", isCategory: true)
        new.readOnly = false
        vm.store.checklist?.items.insert(new, at: index + 1)
        vm.store.registerPersonalChecklistItem(new.id)
        Logger.info("Catégorie ajoutée après l'index \(index)", category: "ChecklistEditor")
    }
    
    private func convertItemType(at index: Int) {
        guard var items = vm.store.checklist?.items, items.indices.contains(index) else { return }
        
        let currentItem = items[index]
        let newItem = ChecklistItem(
            id: currentItem.id,
            title: currentItem.title,
            isCategory: !currentItem.isCategory,
            checked: currentItem.checked,
            notes: currentItem.notes
        )
        
        items[index] = newItem
        vm.store.checklist?.items = items
        Logger.info("Type d'élément converti à l'index \(index)", category: "ChecklistEditor")
    }
    
    /// Supprime les éléments aux indices spécifiés (pour le mode édition standard)
    private func deleteItems(at offsets: IndexSet) {
        guard var items = vm.store.checklist?.items else { return }
        
        // Calculer tous les indices à supprimer en une seule passe
        var allIndicesToDelete = Set<Int>()
        
        for index in offsets {
            guard items.indices.contains(index) else { continue }
            let item = items[index]
            
            if item.isCategory {
                // Ajouter la catégorie et toutes ses questions associées
                allIndicesToDelete.insert(index)
                let questionsToDelete = findQuestionsInCategory(at: index, in: items)
                allIndicesToDelete.formUnion(questionsToDelete)
            } else {
                // Ajouter simplement la question
                allIndicesToDelete.insert(index)
            }
        }
        
        // Supprimer tous les indices en ordre décroissant pour éviter les problèmes d'indexation
        let sortedIndicesToDelete = allIndicesToDelete.sorted(by: >)
        for index in sortedIndicesToDelete {
            if items.indices.contains(index) {
                items.remove(at: index)
            }
        }
        
        vm.store.checklist?.items = items
        Logger.info("\(sortedIndicesToDelete.count) élément(s) supprimé(s)", category: "ChecklistEditor")
    }
    
    /// Supprime un élément spécifique avec sa catégorie si nécessaire
    private func deleteItem(at index: Int, item: ChecklistItem) {
        guard var items = vm.store.checklist?.items, items.indices.contains(index) else { return }
        
        if item.isCategory {
            // Supprimer la catégorie et toutes ses questions associées
            let questionsToDelete = findQuestionsInCategory(at: index, in: items)
            let allIndicesToDelete = [index] + questionsToDelete
            
            // Supprimer en ordre décroissant pour éviter les problèmes d'indexation
            for idx in allIndicesToDelete.sorted(by: >) {
                if items.indices.contains(idx) {
                    items.remove(at: idx)
                }
            }
            Logger.info("Catégorie et \(questionsToDelete.count) question(s) supprimée(s)", category: "ChecklistEditor")
        } else {
            // Supprimer simplement la question
            items.remove(at: index)
            Logger.info("Question supprimée", category: "ChecklistEditor")
        }
        
        vm.store.checklist?.items = items
    }
    
    /// Trouve toutes les questions appartenant à une catégorie donnée
    /// Les questions sont celles qui suivent la catégorie jusqu'à la prochaine catégorie ou la fin
    private func findQuestionsInCategory(at categoryIndex: Int, in items: [ChecklistItem]) -> [Int] {
        guard items.indices.contains(categoryIndex), items[categoryIndex].isCategory else { return [] }
        
        var questionIndices: [Int] = []
        var currentIndex = categoryIndex + 1
        
        // Parcourir les éléments après la catégorie jusqu'à trouver une autre catégorie ou la fin
        while currentIndex < items.count {
            if items[currentIndex].isCategory {
                // On a atteint une autre catégorie, arrêter
                break
            } else {
                // C'est une question de cette catégorie
                questionIndices.append(currentIndex)
            }
            currentIndex += 1
        }
        
        return questionIndices
    }
    
    /// Compte le nombre de questions dans une catégorie
    private func countQuestionsInCategory(at categoryIndex: Int) -> Int {
        guard let items = vm.store.checklist?.items else { return 0 }
        return findQuestionsInCategory(at: categoryIndex, in: items).count
    }
    
    private func createEmptyChecklist() {
        // Utiliser la fonction du ViewModel
        vm.createEmptyChecklist()
        Logger.info("Checklist vide créée", category: "ChecklistEditor")
    }
}

// MARK: - Sous-vues privées

private extension ChecklistEditorView {
    /// Construit une ligne d'édition pour un élément de checklist avec l'ensemble des actions associées
    @ViewBuilder
    func editorRow(for item: ChecklistItem, at index: Int, isReadOnly: Bool) -> some View {
        ChecklistEditorRow(
            item: item,
            isReadOnly: isReadOnly,
            onUpdate: { newTitle in
                guard var checklist = vm.store.checklist,
                      checklist.items.indices.contains(index) else { return }
                checklist.items[index].title = newTitle
                vm.store.checklist = checklist
            },
            onUpdateNotes: { newNotes in
                guard var checklist = vm.store.checklist,
                      checklist.items.indices.contains(index) else { return }
                checklist.items[index].notes = newNotes
                vm.store.checklist = checklist
            },
            onAddQuestion: {
                addQuestionAfterIndex(index)
            },
            onAddCategory: {
                addCategoryAfterIndex(index)
            },
            onConvertType: {
                convertItemType(at: index)
            },
            onDelete: {
                prepareDeletion(at: index)
            },
            editMode: editMode
        )
    }

    private func prepareDeletion(at index: Int) {
        guard let checklist = vm.store.checklist,
              checklist.items.indices.contains(index) else { return }
        itemToDelete = (index: index, item: checklist.items[index])
        showingDeleteConfirmation = true
    }

    private func handleDriverFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                driverImportErrorMessage = "Impossible d'accéder au fichier. Assurez-vous qu'il est stocké dans Fichiers et réessayez."
                Logger.error("Impossible d'accéder au fichier conducteurs: \(url.path)", category: "ChecklistEditor")
                return
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            driverImportResults = vm.importDriversJSON(from: url)

            if driverImportResults.count == 1, case .error = driverImportResults.first {
                driverImportResults = [vm.importDriverJSON(from: url)]
            }

            processDriverImportResults()

        case .failure(let error):
            driverImportErrorMessage = "Erreur lors de la sélection du fichier : \(error.localizedDescription)"
            Logger.error("Erreur de sélection de fichier conducteurs: \(error.localizedDescription)", category: "ChecklistEditor")
        }
    }

    private func processDriverImportResults() {
        var newDriversCount = 0
        var errors: [String] = []
        var waitingMerge = false

        for (index, result) in driverImportResults.enumerated() {
            switch result {
            case .newDriver(let driver, _, _, _):
                vm.addImportedDriver(driver)
                newDriversCount += 1
                Logger.info("Conducteur importé: \(driver.name)", category: "ChecklistEditor")

            case .existingDriver(let driverIndex, let importedDriver, _, _):
                if !waitingMerge {
                    pendingMergeDriver = importedDriver
                    pendingMergeIndex = driverIndex
                    driverImportResults = Array(driverImportResults.dropFirst(index + 1))
                    showingDriverMergeDialog = true
                    waitingMerge = true
                    return
                }

            case .error(let message):
                errors.append(message)
                Logger.error("Erreur d'import conducteur: \(message)", category: "ChecklistEditor")
            }
        }

        if newDriversCount > 0 {
            driverImportSuccessMessage = "Import réussi : \(newDriversCount) conducteur(s) ajouté(s)"
        }

        if !errors.isEmpty {
            driverImportErrorMessage = errors.joined(separator: "\n")
        }

        driverImportResults = []
    }

    private func handleDriverMerge(strategy: MergeStrategy) {
        guard let driver = pendingMergeDriver else {
            showingDriverMergeDialog = false
            processDriverImportResults()
            return
        }

        vm.mergeDriver(driver, at: pendingMergeIndex, strategy: strategy)
        pendingMergeDriver = nil
        showingDriverMergeDialog = false
        Logger.info("Fusion de conducteur avec stratégie: \(strategy.title)", category: "ChecklistEditor")

        processDriverImportResults()
    }
}
