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
    
    var body: some View {
        VStack {
            if manager.isScanning {
                ImagePickerView(manager: manager)
                    .edgesIgnoringSafeArea(.all)
            } else if manager.isProcessing {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Extracting data...")
                        .padding(.top, 8)
                }
            } else {
                ScrollView {
                    Text(manager.scannedText.isEmpty ? "No text found" : manager.scannedText)
                        .padding()
                }
            }
        }
        .navigationTitle("Scan Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            if !manager.isScanning {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Retake") {
                        manager.scannedText = ""
                        manager.isScanning = true
                    }
                }
            }
        }
    }
}

struct ImagePickerView: UIViewControllerRepresentable {
    @ObservedObject var manager: CameraManager
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = manager
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

#Preview {
    CameraView()
}
