//
//  PDFReportGenerator.swift
//  RailSkills
//
//  Service de génération de rapports PDF
//

import Foundation
import UIKit

/// Utilitaire pour générer des rapports PDF
enum PDFReportGenerator {
    static func generatePDF(forDrivers drivers: [DriverRecord], vm: AppViewModel) -> URL {
        let pageWidth: CGFloat = 595.0
        let pageHeight: CGFloat = 842.0
        let margin: CGFloat = 36.0
        let contentRect = CGRect(x: margin, y: margin, width: pageWidth - 2*margin, height: pageHeight - 2*margin)

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Suivi_\(Int(Date().timeIntervalSince1970)).pdf")

        // Utilisation de la police système iOS pour les PDFs
        let titleFont = UIFont.avenirTitlePDF
        let headerFont = UIFont.avenirHeaderPDF
        let subHeaderFont = UIFont.avenirSubHeaderPDF
        let bodyFont = UIFont.avenirBodyPDF
        let captionFont = UIFont.avenirCaptionPDF
        let footnoteFont = UIFont.avenirFootnotePDF

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.lineSpacing = 4
        
        func draw(text: String, at point: CGPoint, font: UIFont, color: UIColor = .label, alignment: NSTextAlignment = .left) -> CGFloat {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.alignment = alignment
            paragraphStyle.lineSpacing = 4
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle
            ]
            let maxSize = CGSize(width: contentRect.width, height: .greatestFiniteMagnitude)
            let rect = text.boundingRect(with: maxSize, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
            let drawRect = CGRect(origin: point, size: rect.size)
            text.draw(in: drawRect, withAttributes: attributes)
            return rect.height
        }

        func addPage(_ context: UIGraphicsPDFRendererContext) { context.beginPage() }
        
        // Fonction helper pour les couleurs conditionnelles
        func labelColorForDays(_ days: Int) -> UIColor {
            if days <= 0 { return .systemRed }
            if days <= 90 { return .systemOrange }
            return .label
        }
        
        // Dessiner l'en-tête de page
        func drawPageHeader(_ context: UIGraphicsPDFRendererContext, pageNumber: Int, totalPages: Int, title: String) {
            let headerRect = CGRect(x: margin, y: 20, width: pageWidth - 2*margin, height: 30)
            let headerText = "\(title) — Page \(pageNumber)/\(totalPages)"
            _ = draw(text: headerText, at: CGPoint(x: headerRect.minX, y: headerRect.midY - 5), font: captionFont, color: .secondaryLabel, alignment: .right)
            
            // Ligne de séparation
            let path = UIBezierPath()
            path.move(to: CGPoint(x: margin, y: headerRect.maxY))
            path.addLine(to: CGPoint(x: pageWidth - margin, y: headerRect.maxY))
            path.lineWidth = 0.5
            UIColor.secondaryLabel.setStroke()
            path.stroke()
        }

        try? renderer.writePDF(to: url, withActions: { context in
            // Calculer le nombre total de pages approximatif
            let estimatedPagesPerDriver = 3
            let totalEstimatedPages = drivers.count * estimatedPagesPerDriver
            
            for (driverIndex, driver) in drivers.enumerated() {
                // Page de couverture
                addPage(context)
                var cursorY = contentRect.minY + 60
                
                drawPageHeader(context, pageNumber: driverIndex * estimatedPagesPerDriver + 1, totalPages: totalEstimatedPages, title: "RailSkills")
                
                let appTitle = vm.store.checklist?.title ?? "Checklist"
                let titleLine = "\(appTitle)"
                cursorY += draw(text: titleLine, at: CGPoint(x: contentRect.minX, y: cursorY), font: titleFont)
                cursorY += 20
                
                let subtitle = "Rapport de suivi"
                cursorY += draw(text: subtitle, at: CGPoint(x: contentRect.minX, y: cursorY), font: subHeaderFont, color: .secondaryLabel)
                cursorY += 40
                
                cursorY += draw(text: "Conducteur:", at: CGPoint(x: contentRect.minX, y: cursorY), font: bodyFont, color: .secondaryLabel)
                cursorY += 8
                cursorY += draw(text: driver.name, at: CGPoint(x: contentRect.minX, y: cursorY), font: headerFont)
                cursorY += 30
                
                var progressPercent = 0
                if let cl = vm.store.checklist {
                    let questions = cl.questions
                    let key = cl.title
                    let map = driver.checklistStates[key] ?? [:]
                    let checked = questions.filter { map[$0.id] == 2 }.count
                    progressPercent = questions.isEmpty ? 0 : Int((Double(checked) / Double(questions.count)) * 100)
                }
                cursorY += draw(text: "Progression globale: \(progressPercent)%", at: CGPoint(x: contentRect.minX, y: cursorY), font: bodyFont)
                cursorY += 12

                if let start = driver.triennialStart, let due = Calendar.current.date(byAdding: .year, value: 3, to: start) {
                    let cal = Calendar.current
                    let startDay = cal.startOfDay(for: Date())
                    let endDay = cal.startOfDay(for: due)
                    let remaining = cal.dateComponents([.day], from: startDay, to: endDay).day ?? 0
                    let statusText = remaining <= 0 ? "Échu depuis \(-remaining) jours" : "\(remaining) jours restants"
                    cursorY += draw(text: "Échéance triennale: \(DateFormatHelper.formatDate(due))", at: CGPoint(x: contentRect.minX, y: cursorY), font: bodyFont)
                    cursorY += 8
                    cursorY += draw(text: "Statut: \(statusText)", at: CGPoint(x: contentRect.minX, y: cursorY), font: bodyFont, color: labelColorForDays(remaining))
                }
                
                cursorY += 30
                cursorY += draw(text: "Date d'export: \(DateFormatHelper.formatDate(Date()))", at: CGPoint(x: contentRect.minX, y: cursorY), font: captionFont, color: .secondaryLabel)

                // Table des matières (si plusieurs catégories)
                if let cl = vm.store.checklist {
                    let categories = cl.items.filter { $0.isCategory }
                    if categories.count > 1 {
                        cursorY = contentRect.maxY - 150
                        cursorY += draw(text: "Table des matières", at: CGPoint(x: contentRect.minX, y: cursorY), font: headerFont)
                        cursorY += 8
                        
                        for (index, category) in categories.enumerated() {
                            let tocLine = "\(index + 1). \(category.title)"
                            let textHeight = draw(text: tocLine, at: CGPoint(x: contentRect.minX + 10, y: cursorY), font: captionFont)
                            cursorY += textHeight + 6
                        }
                    }
                }

                cursorY = contentRect.maxY - 30
                _ = draw(text: "Généré par RailSkills v2.0", at: CGPoint(x: contentRect.minX, y: cursorY), font: footnoteFont, color: .secondaryLabel, alignment: .center)

                // Page de contenu détaillé
                addPage(context)
                cursorY = contentRect.minY
                
                drawPageHeader(context, pageNumber: driverIndex * estimatedPagesPerDriver + 2, totalPages: totalEstimatedPages, title: driver.name)
                
                cursorY += 10
                cursorY += draw(text: "Détail des questions", at: CGPoint(x: contentRect.minX, y: cursorY), font: headerFont)
                cursorY += 12

                if let cl = vm.store.checklist {
                    let notesMap = driver.checklistNotes[cl.title] ?? [:]
                    let datesMap = driver.checklistDates[cl.title] ?? [:]
                    var currentPage = driverIndex * estimatedPagesPerDriver + 2
                    
                    for item in cl.items {
                        // Vérifier si on doit ajouter une nouvelle page
                        if cursorY > contentRect.maxY - 60 {
                            addPage(context)
                            currentPage += 1
                            cursorY = contentRect.minY
                            drawPageHeader(context, pageNumber: currentPage, totalPages: totalEstimatedPages, title: driver.name)
                            cursorY += 10
                        }
                        
                        if item.isCategory {
                            cursorY += 8
                            cursorY += draw(text: item.title, at: CGPoint(x: contentRect.minX, y: cursorY), font: subHeaderFont, color: .systemBlue)
                            cursorY += 6
                            // Ligne de séparation sous la catégorie
                            let path = UIBezierPath()
                            path.move(to: CGPoint(x: contentRect.minX, y: cursorY))
                            path.addLine(to: CGPoint(x: contentRect.maxX, y: cursorY))
                            path.lineWidth = 0.5
                            UIColor.secondaryLabel.setStroke()
                            path.stroke()
                            cursorY += 4
                        } else {
                            let key = cl.title
                            let map = driver.checklistStates[key] ?? [:]
                            let s = map[item.id] ?? 0
                            let mark: String
                            switch s {
                            case 3: mark = "⊘ Non applicable"
                            case 2: mark = "☑ Validé"
                            case 1: mark = "◪ Partiel"
                            default: mark = "☐ Non validé"
                            }
                            let line = "\(mark) \(item.title)"
                            cursorY += draw(text: line, at: CGPoint(x: contentRect.minX + 8, y: cursorY), font: bodyFont)
                            
                            // Afficher la date de suivi si disponible
                            if let evalDate = datesMap[item.id] {
                                let dateText = "   Suivi le \(DateFormatHelper.formatDate(evalDate))"
                                let dateHeight = draw(text: dateText, at: CGPoint(x: contentRect.minX + 16, y: cursorY + 6), font: captionFont, color: .secondaryLabel)
                                cursorY += dateHeight + 2
                            }
                            
                            if let note = notesMap[item.id], !note.isEmpty {
                                let noteText = "   Note: \(note)"
                                let noteHeight = draw(text: noteText, at: CGPoint(x: contentRect.minX + 16, y: cursorY + 6), font: captionFont, color: .secondaryLabel)
                                cursorY += noteHeight + 4
                            }
                            cursorY += 8
                        }
                    }
                }

                // Page de synthèse statistiques
                if let cl = vm.store.checklist {
                    addPage(context)
                    cursorY = contentRect.minY
                    
                    drawPageHeader(context, pageNumber: driverIndex * estimatedPagesPerDriver + 3, totalPages: totalEstimatedPages, title: driver.name)
                    
                    cursorY += 10
                    cursorY += draw(text: "Synthèse statistique", at: CGPoint(x: contentRect.minX, y: cursorY), font: headerFont)
                    cursorY += 16
                    
                    let questions = cl.questions
                    let key = cl.title
                    let map = driver.checklistStates[key] ?? [:]
                    let validated = questions.filter { map[$0.id] == 2 }.count
                    let partial = questions.filter { map[$0.id] == 1 }.count
                    let notValidated = questions.filter { map[$0.id] == 0 }.count
                    let notApplicable = questions.filter { map[$0.id] == 3 }.count
                    let total = questions.count
                    
                    cursorY += draw(text: "Total de questions: \(total)", at: CGPoint(x: contentRect.minX, y: cursorY), font: bodyFont)
                    cursorY += 12
                    cursorY += draw(text: "☑ Validées: \(validated) (\(total > 0 ? Int((Double(validated) / Double(total)) * 100) : 0)%)", at: CGPoint(x: contentRect.minX + 20, y: cursorY), font: bodyFont, color: .systemGreen)
                    cursorY += 12
                    cursorY += draw(text: "◪ Partielles: \(partial) (\(total > 0 ? Int((Double(partial) / Double(total)) * 100) : 0)%)", at: CGPoint(x: contentRect.minX + 20, y: cursorY), font: bodyFont, color: .systemOrange)
                    cursorY += 12
                    cursorY += draw(text: "☐ Non validées: \(notValidated) (\(total > 0 ? Int((Double(notValidated) / Double(total)) * 100) : 0)%)", at: CGPoint(x: contentRect.minX + 20, y: cursorY), font: bodyFont, color: .systemRed)
                    cursorY += 12
                    cursorY += draw(text: "⊘ Non applicables: \(notApplicable)", at: CGPoint(x: contentRect.minX + 20, y: cursorY), font: bodyFont, color: .systemGray)
                    
                    // Statistiques par catégorie
                    let categories = cl.items.filter { $0.isCategory }
                    if !categories.isEmpty {
                        cursorY += 24
                        cursorY += draw(text: "Progression par catégorie:", at: CGPoint(x: contentRect.minX, y: cursorY), font: subHeaderFont)
                        cursorY += 12
                        
                        var currentCategoryId: UUID?
                        var categoryItems: [ChecklistItem] = []
                        
                        for item in cl.items {
                            if item.isCategory {
                                // Afficher la progression de la catégorie précédente
                                if let catId = currentCategoryId {
                                    let categoryQuestions = categoryItems
                                    let categoryTotal = categoryQuestions.count
                                    let categoryValidated = categoryQuestions.filter { map[$0.id] == 2 }.count
                                    let categoryPercent = categoryTotal > 0 ? Int((Double(categoryValidated) / Double(categoryTotal)) * 100) : 0
                                    if let catItem = cl.items.first(where: { $0.id == catId }) {
                                        cursorY += draw(text: "• \(catItem.title): \(categoryValidated)/\(categoryTotal) (\(categoryPercent)%)", at: CGPoint(x: contentRect.minX + 20, y: cursorY), font: captionFont)
                                        cursorY += 8
                                    }
                                }
                                currentCategoryId = item.id
                                categoryItems = []
                            } else if currentCategoryId != nil {
                                categoryItems.append(item)
                            }
                        }
                        
                        // Dernière catégorie
                        if let catId = currentCategoryId, !categoryItems.isEmpty {
                            let categoryTotal = categoryItems.count
                            let categoryValidated = categoryItems.filter { map[$0.id] == 2 }.count
                            let categoryPercent = categoryTotal > 0 ? Int((Double(categoryValidated) / Double(categoryTotal)) * 100) : 0
                            if let catItem = cl.items.first(where: { $0.id == catId }) {
                                cursorY += draw(text: "• \(catItem.title): \(categoryValidated)/\(categoryTotal) (\(categoryPercent)%)", at: CGPoint(x: contentRect.minX + 20, y: cursorY), font: captionFont)
                            }
                        }
                    }
                }
            }
        })

        return url
    }
}

