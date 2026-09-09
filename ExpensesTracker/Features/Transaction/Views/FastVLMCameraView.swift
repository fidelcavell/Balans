//
//  FastVLMCameraView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 09/09/26.
//

import SwiftUI

struct FastVLMCameraView: View {
    @State private var vlmManager = FastVLMManager.shared
    @Environment(\.dismiss) var dismiss

    // Camera state
    @State private var showImagePicker = true
    @State private var capturedImage: UIImage?

    // Prompt configuration (matching official FastVLM demo app)
    @State private var prompt: String = FastVLMManager.defaultPrompt
    @State private var promptSuffix: String = FastVLMManager.defaultPromptSuffix
    @State private var selectedPresetId: String = "final-total"
    @State private var isCustomizingPrompt = false

    // Processing & Navigation
    @State private var errorMessage: String?
    @State private var navigateToReview = false

    private var fullPrompt: String {
        let p = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let s = promptSuffix.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return p }
        return "\(p) \(s)"
    }

    private var statusBackgroundColor: Color {
        switch vlmManager.evaluationState {
        case .idle:
            return .secondary
        case .processingPrompt:
            return .yellow
        case .generatingResponse:
            return .green
        }
    }

    private var statusTextColor: Color {
        vlmManager.evaluationState == .processingPrompt ? .black : .white
    }

    var body: some View {
        Group {
            if showImagePicker && capturedImage == nil {
                FastVLMImagePickerView { image in
                    capturedImage = image
                    showImagePicker = false
                    processWithFastVLM(image: image)
                } onCancel: {
                    showImagePicker = false
                }

            } else if vlmManager.isGenerating {
                VStack(spacing: 16) {
                    imagePreviewWithTTFT

                    // Evaluation state badge matching official demo
                    statusBadge

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.1)

                    if !vlmManager.generatedText.isEmpty {
                        GroupBox {
                            Text(vlmManager.generatedText)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } label: {
                            Text("Live Output")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal)
                    }

                    Button("Cancel") {
                        vlmManager.cancel()
                    }
                    .buttonStyle(.bordered)
                    .tint(.secondary)
                }
                .padding()

            } else if let errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)

                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Button("Change Prompt") {
                            isCustomizingPrompt = true
                        }
                        .buttonStyle(.bordered)

                        Button("Try Again") {
                            if let img = capturedImage {
                                processWithFastVLM(image: img)
                            } else {
                                reset()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()

            } else if !vlmManager.generatedText.isEmpty {
                // Show results
                ScrollView {
                    VStack(spacing: 16) {
                        imagePreviewWithTTFT

                        statusBadge

                        // Parsed Final Amount Card
                        if let amount = vlmManager.extractAmount() {
                            VStack(spacing: 8) {
                                Text("Final Customer Payment Amount")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)

                                Text(amount, format: .currency(code: "IDR"))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundStyle(.primary)

                                Button {
                                    navigateToReview = true
                                } label: {
                                    Label("Use in Transaction", systemImage: "arrow.right.circle.fill")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        } else {
                            VStack(spacing: 6) {
                                Text("No single amount detected")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                Text("Try adjusting the prompt or selecting another preset.")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        // Active Prompt Info & Quick Action
                        promptSummaryCard

                        // Raw Model Output Box
                        GroupBox {
                            Text(vlmManager.generatedText)
                                .font(.system(.subheadline, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        } label: {
                            Label("Raw Model Output", systemImage: "text.bubble")
                                .font(.headline)
                        }

                        // Action Buttons
                        HStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = vlmManager.generatedText
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)

                            if let capturedImage {
                                Button {
                                    processWithFastVLM(image: capturedImage)
                                } label: {
                                    Label("Re-scan", systemImage: "arrow.clockwise")
                                }
                                .buttonStyle(.bordered)
                            }

                            Button { reset() } label: {
                                Label("Scan Another", systemImage: "camera")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                }

            } else if !showImagePicker && capturedImage == nil {
                // User cancelled the picker
                VStack(spacing: 12) {
                    Text("No image captured")
                        .foregroundStyle(.secondary)
                    Button("Open Camera") { reset() }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("FastVLM Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Prompts menu matching official FastVLM demo
                Menu {
                    ForEach(FastVLMManager.defaultPresets) { preset in
                        Button {
                            applyPreset(preset)
                        } label: {
                            if selectedPresetId == preset.id {
                                Label(preset.name, systemImage: "checkmark")
                            } else {
                                Text(preset.name)
                            }
                        }
                    }

                    Divider()

                    Button {
                        isCustomizingPrompt = true
                    } label: {
                        Label("Customize Prompt...", systemImage: "slider.horizontal.3")
                    }
                } label: {
                    Text("Prompts")
                }

                if !showImagePicker && !vlmManager.isGenerating {
                    Button("Retake") { reset() }
                }
            }
        }
        .sheet(isPresented: $isCustomizingPrompt) {
            promptCustomizeSheet
        }
        .navigationDestination(isPresented: $navigateToReview) {
            if let amount = vlmManager.extractAmount() {
                NewTransactionView(prefilled: ExtractedReceiptData(amount: amount))
            }
        }
        .onDisappear {
            vlmManager.cancel()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var imagePreviewWithTTFT: some View {
        if let capturedImage {
            Image(uiImage: capturedImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 220)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .top) {
                    // TTFT overlay like official FastVLM demo
                    if !vlmManager.promptTime.isEmpty {
                        Text("TTFT \(vlmManager.promptTime)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .monospaced()
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(.black.opacity(0.75))
                            }
                            .padding(8)
                    }
                }
        }
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusBackgroundColor)
                .frame(width: 8, height: 8)
            Text(vlmManager.evaluationState.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(statusBackgroundColor == .yellow ? .orange : statusBackgroundColor)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(statusBackgroundColor.opacity(0.12))
        .clipShape(Capsule())
    }

    private var promptSummaryCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Active Prompt", systemImage: "sparkles")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Edit") {
                    isCustomizingPrompt = true
                }
                .font(.caption)
            }

            Text(prompt)
                .font(.subheadline)
                .foregroundStyle(.primary)

            if !promptSuffix.isEmpty {
                Text(promptSuffix)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var promptCustomizeSheet: some View {
        NavigationStack {
            Form {
                Section("Presets") {
                    ForEach(FastVLMManager.defaultPresets) { preset in
                        Button {
                            applyPreset(preset)
                        } label: {
                            HStack {
                                Text(preset.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedPresetId == preset.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                }

                Section("Prompt (Task / Question)") {
                    TextEditor(text: $prompt)
                        .frame(minHeight: 60)
                }

                Section("Prompt Suffix (Output Constraint)") {
                    TextEditor(text: $promptSuffix)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle("Customize Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isCustomizingPrompt = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isCustomizingPrompt = false
                        if let img = capturedImage {
                            processWithFastVLM(image: img)
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Private Methods

    private func applyPreset(_ preset: FastVLMManager.PromptPreset) {
        prompt = preset.prompt
        promptSuffix = preset.promptSuffix
        selectedPresetId = preset.id

        if let capturedImage, !vlmManager.isGenerating {
            processWithFastVLM(image: capturedImage)
        }
    }

    private func processWithFastVLM(image: UIImage) {
        guard vlmManager.isModelLoaded else {
            errorMessage = "FastVLM model is not loaded yet. Please wait for it to finish loading and try again."
            return
        }

        errorMessage = nil
        Task {
            do {
                _ = try await vlmManager.generate(prompt: fullPrompt, image: image)
            } catch {
                errorMessage = "FastVLM processing failed: \(error.localizedDescription)"
            }
        }
    }

    private func reset() {
        vlmManager.cancel()
        capturedImage = nil
        vlmManager.generatedText = ""
        errorMessage = nil
        showImagePicker = true
    }
}

// MARK: - Image Picker Bridge
struct FastVLMImagePickerView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera)
            ? .camera
            : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImageCaptured: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImageCaptured = onImageCaptured
            self.onCancel = onCancel
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
            onCancel()
        }
    }
}

#Preview {
    NavigationStack {
        FastVLMCameraView()
    }
}
