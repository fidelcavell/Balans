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
    
    func extractText(from image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                completion(nil)
                return
            }
            
            let text = observations.compactMap {
                $0.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            completion(text)
        }
        
        // Optimize for accuracy as receipts contain important numbers and text
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                print("Unable to perform the requests: \(error).")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}
