//
//  CameraView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 31/08/26.
//

import SwiftUI
import VisionKit

struct CameraView: View {
    @StateObject private var manager = CameraManager()
    @Environment(\.dismiss) var dismiss
    
    /// Triggers navigation to the pre-filled transaction form once processing is complete (regardless of whether AI parsing succeeded).
    @State private var navigateToReview = false
    
    var body: some View {
        Group {
            if manager.isScanning {
                ImagePickerView(manager: manager)
                    .edgesIgnoringSafeArea(.all)
                
            } else if manager.isProcessing {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                    
                    Text(manager.processingMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .animation(.default, value: manager.processingMessage)
                }
                
            } else if let errorMessage = manager.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                    
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    
                    Button("Try Again") { manager.reset() }
                        .buttonStyle(.borderedProminent)
                }
                .padding()
                
            } else if !manager.isScanning {
                VStack(alignment: .center, spacing: 8) {
                    Text("Receipt's information not found")
                    Text("Try to retake the receipt photo")
                }
            } else {
                // ── Idle / scanned but not yet navigating
                ProgressView()
            }
        }
        .navigationTitle("Scan Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if !manager.isScanning && !manager.isProcessing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Retake") { manager.reset() }
                }
            }
        }
        // ── Navigate to pre-filled transaction form
        .navigationDestination(isPresented: $navigateToReview) {
            NewTransactionView(prefilled: manager.extractedData)
        }
        // ── Trigger navigation once both OCR + AI parsing finish
        .onChange(of: manager.isProcessing) { _, isProcessing in
            if !isProcessing && !manager.scannedText.isEmpty {
                navigateToReview = true
            }
        }
    }
}

// MARK: - Image Picker Bridge
struct ImagePickerView: UIViewControllerRepresentable {
    @ObservedObject var manager: CameraManager
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = manager
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera)
        ? .camera
        : .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

#Preview {
    NavigationStack {
        CameraView()
    }
}
