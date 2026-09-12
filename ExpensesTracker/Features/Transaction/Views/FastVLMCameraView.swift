//
//  FastVLMCameraView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 09/09/26.
//

import SwiftUI

struct FastVLMCameraView: View {
    @State private var vlmManager = FastVLMManager.shared
    @State private var speechService = SpeechRecognitionService.shared
    @Environment(\.dismiss) var dismiss

    // Camera state
    @State private var showImagePicker = true
    @State private var capturedImage: UIImage?

    // Prompt configuration (matching official FastVLM demo app)
    @State private var prompt: String = FastVLMManager.defaultPrompt
    @State private var promptSuffix: String = FastVLMManager.defaultPromptSuffix
    @State private var selectedPresetId: String = "final-total"
    @State private var isCustomizingPrompt = false

    // Voice record state for friends adjustment
    @State private var voicePromptText: String = ""
    @State private var isEditingVoicePrompt = false
    @State private var micAnimationPhase: CGFloat = 0.0

    // Extracted detail & Split navigation
    @State private var extractedDetail: ExtractedReceiptDetail?
    @State private var isShowingItemSelection = false
    @State private var confirmedShareAmount: Double?
    @State private var confirmedShareNote: String?

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

            } else if capturedImage != nil {
                // Main content: image preview, voice adjustment card, and results
                ScrollView {
                    VStack(spacing: 16) {
                        // 1. Scanned Receipt Image Preview with TTFT
                        imagePreviewWithTTFT

                        // 2. Voice Record & Adjustment Prompt Card (beside/below the scanned receipt)
                        voiceAdjustmentCard

                        // 3. Status Badge & Generation Progress
                        statusBadge

                        if vlmManager.isGenerating {
                            VStack(spacing: 12) {
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
                                }

                                Button("Cancel") {
                                    vlmManager.cancel()
                                }
                                .buttonStyle(.bordered)
                                .tint(.secondary)
                            }
                            .padding(.vertical, 8)

                        } else if !vlmManager.generatedText.isEmpty {
                            // 4. Results: Adjusted Items or Single Amount
                            if let detail = extractedDetail, !detail.items.isEmpty {
                                adjustedItemsCard(detail)
                            } else if let amount = vlmManager.extractAmount() {
                                singleAmountCard(amount)
                            } else {
                                noAmountDetectedCard
                            }

                            // 5. Active Prompt Summary Card
                            promptSummaryCard

                            // 6. Raw Model Output Box
                            GroupBox {
                                Text(vlmManager.generatedText)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                            } label: {
                                Label("Raw Model Output", systemImage: "text.bubble")
                                    .font(.headline)
                            }

                            // 7. Action Buttons
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
                // Prompts menu
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
        .sheet(isPresented: $isShowingItemSelection) {
            if let detail = extractedDetail {
                ReceiptItemSelectionView(detail: detail) { shareAmount, shareNote in
                    confirmedShareAmount = shareAmount
                    confirmedShareNote = shareNote
                    navigateToReview = true
                }
            }
        }
        .navigationDestination(isPresented: $navigateToReview) {
            let finalAmt = confirmedShareAmount
                ?? extractedDetail?.grandTotal
                ?? vlmManager.extractAmount()
                ?? 0
            let finalNote = confirmedShareNote
                ?? extractedDetail?.summaryNote(for: Set(extractedDetail?.items.map(\.id) ?? []))
                ?? (!voicePromptText.isEmpty ? "Split: \(voicePromptText)" : nil)

            NewTransactionView(prefilled: ExtractedReceiptData(amount: finalAmt, note: finalNote))
        }
        .onDisappear {
            vlmManager.cancel()
            speechService.stopListening()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var imagePreviewWithTTFT: some View {
        if let capturedImage {
            Image(uiImage: capturedImage)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .top) {
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

    /// Dedicated Voice Prompt Card placed beside / below the scanned receipt
    private var voiceAdjustmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Voice Adjustment (Friends Split)", systemImage: "waveform.badge.mic")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.tint)

                Spacer()

                if !voicePromptText.isEmpty {
                    Button("Clear") {
                        clearVoicePrompt()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            Text("Speak instructions to adjust the number or price of items you bought with friends.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Live Microphone Record Controls
            HStack(spacing: 12) {
                Button {
                    toggleVoiceRecording()
                } label: {
                    ZStack {
                        if speechService.isListening {
                            Circle()
                                .stroke(Color.red.opacity(0.35), lineWidth: 3)
                                .frame(width: 46, height: 46)
                                .scaleEffect(1.0 + micAnimationPhase * 0.15)
                                .animation(
                                    .easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                                    value: micAnimationPhase
                                )
                        }

                        Circle()
                            .fill(speechService.isListening ? Color.red : Color.accentColor)
                            .frame(width: 38, height: 38)

                        Image(systemName: speechService.isListening ? "stop.fill" : "mic.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .onAppear { micAnimationPhase = 1.0 }

                VStack(alignment: .leading, spacing: 2) {
                    Text(speechService.isListening ? "Listening..." : (voicePromptText.isEmpty ? "Tap to record prompt" : "Recorded Prompt"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(speechService.isListening ? .red : .primary)

                    if speechService.isListening {
                        Text(speechService.transcript.isEmpty ? "Say e.g.: \"I bought 2 teas and 1 burger\"" : speechService.transcript)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    } else if !voicePromptText.isEmpty {
                        Text("\"\(voicePromptText)\"")
                            .font(.caption2)
                            .italic()
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                    } else {
                        Text("e.g. \"Saya beli 2 es teh dan 1 burger, pizza dibagi dua\"")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if !voicePromptText.isEmpty && !speechService.isListening {
                    Button {
                        if let img = capturedImage {
                            processWithFastVLM(image: img)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }
            .padding(10)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(12)
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    /// Card displaying adjusted items extracted from the receipt based on voice prompt
    @ViewBuilder
    private func adjustedItemsCard(_ detail: ExtractedReceiptDetail) -> some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Label("Adjusted Items (Friend Split)", systemImage: "person.2.fill")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.tint)
                    Text("\(detail.items.count) item\(detail.items.count == 1 ? "" : "s") identified for your share")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()

                Button {
                    isShowingItemSelection = true
                } label: {
                    Label("Adjust", systemImage: "slider.horizontal.2")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }

            Divider()

            // Item list rows
            VStack(spacing: 8) {
                ForEach(detail.items) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline)
                                .fontWeight(.medium)

                            if item.quantity > 1 {
                                Text("\(item.quantity) × \(item.price, format: .currency(code: "IDR"))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()

                        Text(item.totalPrice, format: .currency(code: "IDR"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }

            // Subtotal / Extra Breakdown
            if detail.tax > 0 || detail.serviceCharge > 0 || detail.discount > 0 {
                Divider()
                VStack(spacing: 4) {
                    if detail.subtotal > 0 {
                        HStack {
                            Text("Subtotal")
                            Spacer()
                            Text(detail.subtotal, format: .currency(code: "IDR"))
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    if detail.tax > 0 {
                        HStack {
                            Text("Tax")
                            Spacer()
                            Text("+\(detail.tax, format: .currency(code: "IDR"))")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    if detail.serviceCharge > 0 {
                        HStack {
                            Text("Service Charge")
                            Spacer()
                            Text("+\(detail.serviceCharge, format: .currency(code: "IDR"))")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    if detail.discount > 0 {
                        HStack {
                            Text("Discount")
                            Spacer()
                            Text("-\(detail.discount, format: .currency(code: "IDR"))")
                        }
                        .font(.caption)
                        .foregroundStyle(.green)
                    }
                }
            }

            Divider()

            // Final Share Amount
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Final Share")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text("Calculated for your items")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                Text(detail.grandTotal, format: .currency(code: "IDR"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            // Primary Action
            Button {
                confirmedShareAmount = detail.grandTotal
                confirmedShareNote = detail.summaryNote(for: Set(detail.items.map(\.id)))
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
    }

    /// Single amount card fallback
    @ViewBuilder
    private func singleAmountCard(_ amount: Double) -> some View {
        VStack(spacing: 8) {
            Text("Final Payment Amount")
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
    }

    private var noAmountDetectedCard: some View {
        VStack(spacing: 6) {
            Text("No single amount detected")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            Text("Try recording a voice prompt or selecting another preset.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
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

    private func toggleVoiceRecording() {
        if speechService.isListening {
            speechService.stopListening()
            let transcript = speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
            if !transcript.isEmpty {
                applyVoicePrompt(transcript)
            }
        } else {
            voicePromptText = ""
            speechService.startListening()
        }
    }

    private func applyVoicePrompt(_ text: String) {
        voicePromptText = text
        let (p, s) = FastVLMManager.buildSplitPrompt(voiceInstruction: text)
        prompt = p
        promptSuffix = s
        selectedPresetId = "friend-split"

        if let img = capturedImage, !vlmManager.isGenerating {
            processWithFastVLM(image: img)
        }
    }

    private func clearVoicePrompt() {
        voicePromptText = ""
        speechService.reset()
        extractedDetail = nil
        applyPreset(FastVLMManager.defaultPresets[0])
    }

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
                let output = try await vlmManager.generate(prompt: fullPrompt, image: image)
                await MainActor.run {
                    self.extractedDetail = self.vlmManager.extractReceiptDetail(from: output)
                }
            } catch {
                errorMessage = "FastVLM processing failed: \(error.localizedDescription)"
            }
        }
    }

    private func reset() {
        vlmManager.cancel()
        speechService.stopListening()
        capturedImage = nil
        vlmManager.generatedText = ""
        extractedDetail = nil
        voicePromptText = ""
        confirmedShareAmount = nil
        confirmedShareNote = nil
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
