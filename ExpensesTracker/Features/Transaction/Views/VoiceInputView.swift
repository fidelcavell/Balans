//
//  VoiceInputView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 08/09/26.
//

import SwiftUI
import SwiftData

/// A sheet view for voice-based transaction input.
///
/// Presents a microphone interface that records the user's speech,
/// transcribes it, and parses it into structured transaction data
/// using the on-device Foundation Model.
struct VoiceInputView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \TransactionLabel.title) private var availableLabels: [TransactionLabel]
    
    @State private var speechService = SpeechRecognitionService.shared
    
    /// The current phase of the voice input flow.
    @State private var phase: InputPhase = .idle
    
    /// The parsed result, delivered back to the caller on dismiss.
    @State private var parsedResult: ExtractedReceiptData?
    
    /// Waveform animation timer.
    @State private var animationPhase: CGFloat = 0
    
    /// Callback invoked with the parsed data when the user taps "Apply".
    var onComplete: (ExtractedReceiptData) -> Void
    
    enum InputPhase: Equatable {
        case idle
        case listening
        case processing
        case done
        case error(String)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                micVisual
                
                transcriptSection
                
                Spacer()
                
                actionButtons
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .navigationTitle("Voice Input")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        speechService.stopListening()
                        dismiss()
                    } label: {
                        Image(systemName: Icon.closeMark)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .onDisappear {
            speechService.stopListening()
        }
        .interactiveDismissDisabled(phase == .listening || phase == .processing)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var micVisual: some View {
        ZStack {
            switch phase {
            case .idle:
                micCircle(color: .secondary.opacity(0.2), icon: Icon.microphone)
                
            case .listening:
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Color.accentColor.opacity(0.15), lineWidth: 2)
                        .frame(width: 120 + CGFloat(index) * 30,
                               height: 120 + CGFloat(index) * 30)
                        .scaleEffect(1.0 + animationPhase * 0.08 * CGFloat(index + 1))
                        .animation(
                            .easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: animationPhase
                        )
                }
                
                micCircle(color: .red, icon: Icon.microphone)
                    .onAppear { animationPhase = 1.0 }
                
            case .processing:
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.4)
                    
                    Text("Analyzing your input...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 120, height: 120)
                
            case .done:
                micCircle(color: .green, icon: "checkmark")
                
            case .error:
                micCircle(color: .orange, icon: Icon.exclamationmarkTriangle)
            }
        }
        .frame(height: 180)
        .animation(.spring(duration: 0.4), value: phase)
    }
    
    private func micCircle(color: Color, icon: String) -> some View {
        Circle()
            .fill(color.gradient)
            .frame(width: 120, height: 120)
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }
    }
    
    @ViewBuilder
    private var transcriptSection: some View {
        VStack(spacing: 8) {
            switch phase {
            case .idle:
                Text("Tap the button below to start speaking")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Try: \"Makan siang 45 ribu kemarin\"")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .italic()
                
            case .listening:
                if speechService.transcript.isEmpty {
                    Text("Listening...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(speechService.transcript)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .transition(.opacity)
                }
                
            case .processing:
                if !speechService.transcript.isEmpty {
                    Text("\"\(speechService.transcript)\"")
                        .font(.callout)
                        .italic()
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
            case .done:
                if let result = parsedResult {
                    resultPreview(result)
                }
                
            case .error(let message):
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .animation(.default, value: phase)
    }
    
    @ViewBuilder
    private func resultPreview(_ data: ExtractedReceiptData) -> some View {
        VStack(spacing: 6) {
            if let amount = data.amount, amount > 0 {
                HStack {
                    Text("Amount")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Rp \(data.formattedAmount)")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
            
            if let note = data.note, !note.isEmpty {
                HStack {
                    Text("Note")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(note)
                        .lineLimit(1)
                }
                .font(.subheadline)
            }
            
            HStack {
                Text("Type")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(data.transactionType.label)
            }
            .font(.subheadline)
            
            if let label = data.suggestedLabelName {
                HStack {
                    Text("Label")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(label)
                }
                .font(.subheadline)
            }
            
            if let date = data.occurredAt {
                HStack {
                    Text("Date")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(date, format: .dateTime.day().month(.abbreviated).year())
                }
                .font(.subheadline)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        switch phase {
        case .idle:
            Button {
                phase = .listening
                speechService.startListening()
            } label: {
                Label("Start Speaking", systemImage: Icon.microphone)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .clipShape(Capsule())
            
        case .listening:
            Button {
                speechService.stopListening()
                processTranscript()
            } label: {
                Label("Done Speaking", systemImage: "stop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.large)
            .clipShape(Capsule())
            .disabled(speechService.transcript.isEmpty)
            
        case .processing:
            EmptyView()
            
        case .done:
            VStack(spacing: 12) {
                Button {
                    if let result = parsedResult {
                        onComplete(result)
                        dismiss()
                    }
                } label: {
                    Text("Apply to Form")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .clipShape(Capsule())
                
                Button {
                    speechService.reset()
                    parsedResult = nil
                    phase = .idle
                } label: {
                    Text("Try Again")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
            
        case .error:
            Button {
                speechService.reset()
                phase = .idle
            } label: {
                Label("Try Again", systemImage: Icon.arrowClockwise)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .clipShape(Capsule())
        }
    }
    
    // MARK: - Logic
    private func processTranscript() {
        let transcript = speechService.transcript
        
        guard !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            phase = .error("No speech was detected. Please try again.")
            return
        }
        
        phase = .processing
        
        let labelNames = availableLabels.map(\.title)
        
        Task {
            let result = await VoiceTranscriptionParserService.shared.parse(
                transcript: transcript,
                availableLabelNames: labelNames
            )
            
            guard let result else {
                phase = .error("Could not parse the transaction. Please try again with a clearer description.")
                return
            }
            
            // ── Validate required fields
            let missingFields = validateResult(result)
            
            if missingFields.isEmpty {
                parsedResult = result
                phase = .done
            } else {
                let fieldList = missingFields.joined(separator: ", ")
                phase = .error("Missing information: \(fieldList).\n\nPlease try again and mention all details clearly.\n\nExample: \"Makan siang 45 ribu kemarin\"")
            }
        }
    }
    
    /// Checks the parsed result for required fields and returns a list of
    /// human-readable names for any that are missing or invalid.
    private func validateResult(_ data: ExtractedReceiptData) -> [String] {
        var missing: [String] = []
        
        if (data.amount ?? 0) <= 0 {
            missing.append("amount")
        }
        
        if data.occurredAt == nil {
            missing.append("date")
        }
        
        if (data.note ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("description/reason")
        }
        
        return missing
    }
}

#Preview {
    VoiceInputView { data in
        print("Received: \(data)")
    }
}
