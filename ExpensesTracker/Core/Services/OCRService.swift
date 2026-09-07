//
//  OCRService.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 31/08/26.
//

import Foundation
import Vision
import UIKit
import CoreImage

final class OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    enum OCRError: Error {
        case invalidImage
        case noDocumentFound
    }
    
    /// A lightweight, UI-friendly representation of what we extracted.
    struct RecognizedDocument {
        let fullText: String
        let paragraphs: [String]
        let tables: [[[String]]]
    }
    
    /// Callback-based convenience wrapper (used by CameraManager).
    func extractText(from image: UIImage, completion: @escaping (RecognizedDocument?) -> Void) {
        Task {
            do {
                let document = try await extractStructuredText(from: image)
                completion(document)
            } catch {
                print("[OCRService] Recognition failed: \(error)")
                completion(nil)
            }
        }
    }
    
    /// Async structured extraction. Automatically picks the best API for the
    /// running OS: `RecognizeDocumentsRequest` (iOS 26+) with a
    /// `VNRecognizeTextRequest` fallback for older deployments.
    func extractStructuredText(from image: UIImage) async throws -> RecognizedDocument {
        let preprocessedImage = preprocessed(image: image)
        
        if #available(iOS 26.0, *) {
            return try await extractWithDocumentRequest(from: preprocessedImage)
        } else {
            print("Entered below iOS 26")
            return try await extractWithTextRequest(from: preprocessedImage)
        }
    }
    
    // MARK: - Image Preprocessing
    /// Converts the image to grayscale and boosts contrast so that faded
    /// thermal-receipt ink is as legible as possible for Vision.
    private func preprocessed(image: UIImage) -> UIImage {
        guard let ciImage = CIImage(image: image) else { return image }
        
        // Fix orientation baked into the image bytes.
        let oriented = ciImage.oriented(forExifOrientation: exifOrientation(from: image.imageOrientation))
        
        // Desaturate + slight contrast & brightness boost. Thermal receipts are low-contrast; these values are tuned for them.
        let params: [String: Any] = [
            kCIInputImageKey: oriented,
            kCIInputSaturationKey: 0.0,   // grayscale
            kCIInputContrastKey:   1.25,  // lift mid-tones
            kCIInputBrightnessKey: 0.04   // compensate for slight darkening
        ]
        guard let colorFilter = CIFilter(name: "CIColorControls", parameters: params),
              let output = colorFilter.outputImage else { return image }
        
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return image }
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: .up)
    }
    
    /// Maps `UIImage.Orientation` to the EXIF integer Vision expects.
    private func exifOrientation(from orientation: UIImage.Orientation) -> Int32 {
        switch orientation {
        case .up:            return 1
        case .down:          return 3
        case .left:          return 8
        case .right:         return 6
        case .upMirrored:    return 2
        case .downMirrored:  return 4
        case .leftMirrored:  return 5
        case .rightMirrored: return 7
        @unknown default:    return 1
        }
    }
    
    // MARK: - iOS 26+ RecognizeDocumentsRequest
    @available(iOS 26.0, *)
    private func extractWithDocumentRequest(from image: UIImage) async throws -> RecognizedDocument {
        guard let cgImage = image.cgImage else { throw OCRError.invalidImage }
        
        var request = RecognizeDocumentsRequest()
        request.textRecognitionOptions.useLanguageCorrection = true
        
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
    
    // MARK: - iOS 16+ VNRecognizeTextRequest fallback
    private func extractWithTextRequest(from image: UIImage) async throws -> RecognizedDocument {
        guard let cgImage = image.cgImage else { throw OCRError.invalidImage }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                
                // Sort top-to-bottom so lines read in natural receipt order.
                let sorted = observations.sorted { $0.boundingBox.maxY > $1.boundingBox.maxY }
                let lines = sorted.compactMap { $0.topCandidates(1).first?.string }
                let fullText = lines.joined(separator: "\n")
                continuation.resume(returning: RecognizedDocument(
                    fullText: fullText,
                    paragraphs: lines,
                    tables: []   // VNRecognizeTextRequest has no table detection
                ))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["id-ID", "en-US"]
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
