//
//  CameraManager.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 31/08/26.
//

import Foundation
import VisionKit
import UIKit
import SwiftUI
internal import Combine

class CameraManager: NSObject, ObservableObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @Published var scannedText: String = ""
    @Published var isScanning: Bool = true
    @Published var isProcessing: Bool = false
    
    @Published var processingMessage: String = "Scanning receipt…"
    @Published var extractedData: ExtractedReceiptData?
    @Published var errorMessage: String?
    
    let ocrService: OCRService
    
    init(ocrService: OCRService = .shared) {
        self.ocrService = ocrService
        super.init()
    }
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        isProcessing = true
        isScanning = false
        processingMessage = "Scanning receipt…"
        
        guard let image = info[.originalImage] as? UIImage else {
            errorMessage = "Failed to capture image"
            isProcessing = false
            picker.dismiss(animated: true)
            return
        }
        
        // ── Step 1: OCR
        ocrService.extractText(from: image) { [weak self] text in
            guard let self else { return }
            
            guard let text, !text.isEmpty else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to extract text from image"
                    self.isProcessing = false
                }
                return
            }
            
            DispatchQueue.main.async {
                self.scannedText = text
                self.processingMessage = "Analyzing with AI…"
            }
            
            // ── Step 2: Foundation Models parsing
            Task { @MainActor [weak self] in
                guard let self else { return }
                
                let labelNames = TransactionLabel.defaults.map(\.title)
                let parsed = await ReceiptParserService.shared.parse(
                    rawText: text,
                    availableLabelNames: labelNames
                )
                
                self.extractedData = parsed
                self.isProcessing = false
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        isScanning = false
    }
    
    // MARK: - Retake Image
    func reset() {
        scannedText = ""
        extractedData = nil
        errorMessage = nil
        processingMessage = "Scanning receipt…"
        isScanning = true
    }
}
