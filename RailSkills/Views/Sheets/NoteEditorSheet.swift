//
//  NoteEditorSheet.swift
//  RailSkills
//
//  Éditeur de notes pour les questions de checklist
//

import SwiftUI
#if canImport(Speech)
import Speech
#endif
#if canImport(AVFoundation)
import AVFoundation
#endif

/// Éditeur de notes optimisé avec support de formatage et compteur de caractères
struct NoteEditorSheet: View {
    let item: ChecklistItem
    @Binding var noteText: String
    let onSave: (String?) -> Void
    let onCancel: () -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    @State private var characterCount: Int = 0
    @State private var isRecording = false
    @State private var recognitionTask: Task<Void, Never>?
    @State private var speechRecognizer: SFSpeechRecognizer?
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var audioEngine: AVAudioEngine?
    @StateObject private var templateManager = NoteTemplateManager.shared
    @State private var showingTemplateManager = false
    
    private let maxCharacters = 500 // Limite raisonnable pour les notes
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                } header: {
                    Text("Question")
                }
                
                Section {
                    ZStack(alignment: .bottomTrailing) {
                        ZStack(alignment: .topLeading) {
                            // Placeholder personnalisé
                            if noteText.isEmpty {
                                Text("Ajoutez vos remarques et observations ici...")
                                    .foregroundStyle(.secondary.opacity(0.5))
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                            
                            TextEditor(text: $noteText)
                                .frame(minHeight: 200)
                                .focused($isTextFieldFocused)
                                .scrollContentBackground(.hidden) // Améliore la performance et réduit les conflits
                                .onChange(of: noteText) { _, newValue in
                                    // Limiter le nombre de caractères
                                    if newValue.count > maxCharacters {
                                        noteText = String(newValue.prefix(maxCharacters))
                                    }
                                    characterCount = noteText.count
                                }
                        }
                        
                        // Bouton dictée vocale (gros et accessible)
                        voiceButton
                            .padding(16)
                    }
                } header: {
                    HStack {
                        Text("Note")
                        Spacer()
                        // Compteur de caractères
                        Text("\(characterCount)/\(maxCharacters)")
                            .font(.caption)
                            .foregroundStyle(characterCount > maxCharacters * 9 / 10 ? .orange : .secondary)
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("💡 Conseils :")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                Text("Soyez précis et concis dans vos remarques")
                            }
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                Text("Notez les points à améliorer ou les observations importantes")
                            }
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                Text("Ces notes seront incluses dans les rapports PDF exportés")
                            }
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
                
                // Templates rapides
                Section {
                    noteTemplates
                    
                    Button {
                        showingTemplateManager = true
                    } label: {
                        HStack {
                            Image(systemName: "gearshape.fill")
                            Text("Gérer les templates")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    }
                } header: {
                    Text("Templates rapides")
                } footer: {
                    Text("Appuyez sur un template pour l'ajouter à votre note")
                        .font(.caption2)
                        .foregroundStyle(.primary.opacity(0.6))
                }
                
                // Actions rapides
                Section {
                    Button(role: .destructive) {
                        withAnimation {
                            noteText = ""
                            characterCount = 0
                        }
                    } label: {
                        Label("Effacer la note", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Éditer la note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(trimmed.isEmpty ? nil : trimmed)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button {
                        // Utiliser un délai pour éviter les conflits de contraintes
                        DispatchQueue.main.async {
                            isTextFieldFocused = false
                        }
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
            .onAppear {
                characterCount = noteText.count
                // Utiliser un délai pour éviter les conflits de contraintes lors de l'apparition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isTextFieldFocused = true
                }
            }
            .sheet(isPresented: $showingTemplateManager) {
                NavigationStack {
                    NoteTemplatesManagerView()
                }
            }
        }
    }
    
    /// Vue des templates rapides (dynamiques depuis NoteTemplateManager)
    private var noteTemplates: some View {
        VStack(spacing: 12) {
            if templateManager.templates.isEmpty {
                Text("Aucun template disponible")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(templateManager.templates) { template in
                    templateButton(template.text, icon: template.icon, color: template.color)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    /// Bouton de template individuel
    private func templateButton(_ text: String, icon: String, color: Color) -> some View {
        Button {
            addTemplate(text)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 32)
                
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    /// Ajoute un template à la note existante
    private func addTemplate(_ template: String) {
        withAnimation {
            if noteText.isEmpty {
                noteText = template
            } else {
                // Ajouter sur une nouvelle ligne si la note n'est pas vide
                if !noteText.hasSuffix("\n") {
                    noteText += "\n"
                }
                noteText += template
            }
            characterCount = noteText.count
            
            // Feedback haptique
            #if canImport(UIKit)
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
            #endif
        }
    }
    
    /// Bouton de dictée vocale
    private var voiceButton: some View {
        Button {
            toggleDictation()
        } label: {
            ZStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.blue)
                    .frame(width: 64, height: 64)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                if isRecording {
                    // Animation pulsante pendant l'enregistrement
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 64, height: 64)
                        .scaleEffect(isRecording ? 1.3 : 1.0)
                        .opacity(isRecording ? 0 : 1)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false), value: isRecording)
                }
                
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }
        }
        .accessibilityLabel(isRecording ? "Arrêter la dictée" : "Commencer la dictée")
        .accessibilityHint("Double-tapez pour \(isRecording ? "arrêter" : "commencer") la reconnaissance vocale")
    }
    
    /// Bascule la dictée vocale
    private func toggleDictation() {
        if isRecording {
            stopSpeechRecognition()
        } else {
            startSpeechRecognition()
        }
    }
    
    /// Démarre la reconnaissance vocale
    private func startSpeechRecognition() {
        #if canImport(Speech)
        // Vérifier les autorisations
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                guard authStatus == .authorized else {
                    // TODO: Afficher une alerte d'erreur
                    return
                }
                
                // Initialiser le recognizer
                speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "fr-FR"))
                guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
                    return
                }
                
                do {
                    // Configurer l'audio engine
                    audioEngine = AVAudioEngine()
                    guard let audioEngine = audioEngine else { return }
                    
                    let inputNode = audioEngine.inputNode
                    
                    // Créer la requête de reconnaissance
                    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
                    guard let recognitionRequest = recognitionRequest else { return }
                    
                    recognitionRequest.shouldReportPartialResults = true
                    
                    // Démarrer la reconnaissance
                    speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                        if let result = result {
                            DispatchQueue.main.async {
                                let recognizedText = result.bestTranscription.formattedString
                                
                                // Ajouter le texte reconnu à la note
                                if noteText.isEmpty {
                                    noteText = recognizedText
                                } else {
                                    if !noteText.hasSuffix(" ") && !noteText.hasSuffix("\n") {
                                        noteText += " "
                                    }
                                    noteText += recognizedText
                                }
                            }
                        }
                        
                        if error != nil {
                            stopSpeechRecognition()
                        }
                    }
                    
                    // Configurer le format audio
                    let recordingFormat = inputNode.outputFormat(forBus: 0)
                    inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                        recognitionRequest.append(buffer)
                    }
                    
                    // Démarrer l'audio engine
                    audioEngine.prepare()
                    try audioEngine.start()
                    
                    isRecording = true
                    
                    // Feedback haptique
                    #if canImport(UIKit)
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    #endif
                    
                } catch {
                    stopSpeechRecognition()
                }
            }
        }
        #endif
    }
    
    /// Arrête la reconnaissance vocale
    private func stopSpeechRecognition() {
        #if canImport(Speech)
        isRecording = false
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // Feedback haptique
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
        #endif
    }
}





