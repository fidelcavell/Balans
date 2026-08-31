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
    @Published var errorMessage: String?
    
    let ocrService: OCRService
    
    init(ocrService: OCRService = .shared) {
        self.ocrService = ocrService
        super.init()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.isProcessing = true
        self.isScanning = false
        
        guard let image = info[.originalImage] as? UIImage else {
            self.errorMessage = "Failed to capture image"
            self.isProcessing = false
            picker.dismiss(animated: true)
            return
        }
        
        ocrService.extractText(from: image) { [weak self] text in
            DispatchQueue.main.async {
                if let text = text {
                    self?.scannedText = text
                } else {
                    self?.errorMessage = "Failed to extract text"
                }
                self?.isProcessing = false
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.isScanning = false
    }
}
