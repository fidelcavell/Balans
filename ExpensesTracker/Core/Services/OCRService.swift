//
//  OCRService.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 31/08/26.
//

import Foundation
import Vision
import UIKit

final class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    enum OCRError: Error {
        case invalidImage
        case noDocumentFound
    }
    
    // A lightweight, UI-friendly representation of what we extracted.
    struct RecognizedDocument {
        let fullText: String
        let paragraphs: [String]
        let tables: [[[String]]] // [table][row][cell]
    }
    
    func extractText(from image: UIImage, completion: @escaping (String?) -> Void) {
        Task {
            do {
                let document = try await extractStructuredText(from: image)
                completion(document.fullText)
            } catch {
                print("Document recognition failed: \(error)")
                completion(nil)
            }
        }
    }
    
    // MARK: - New structured API by Vision Framework (iOS 26+)
    @available(iOS 26.0, *)
    func extractStructuredText(from image: UIImage) async throws -> RecognizedDocument {
        guard let cgImage = image.cgImage else {
            throw OCRError.invalidImage
        }
        
        let request = RecognizeDocumentsRequest()
        let observations = try await request.perform(on: cgImage)
        
        guard let document = observations.first?.document else {
            throw OCRError.noDocumentFound
        }
        
        let tables: [[[String]]] = document.tables.map { table in
            table.rows.map { row in
                row.map { $0.content.text.transcript }
            }
        }
        
        return RecognizedDocument(
            fullText: document.text.transcript,
            paragraphs: document.paragraphs.map { $0.transcript },
            tables: tables
        )
    }
}
