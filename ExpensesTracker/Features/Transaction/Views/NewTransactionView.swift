//
//  NewTransactionView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 30/06/26.
//

import SwiftUI
import SwiftData

struct NewTransactionView: View {
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TransactionViewModel = TransactionViewModel()
    
    @State private var occurredAt: Date
    @State private var amount: String
    @State private var selectedType: TransactionType
    @State private var selectedLabel: TransactionLabel?
    @State private var transactionNote: String
    
    // ── AI-suggested label title for post-load matching
    /// Stored separately because `availableLabels` isn't populated until the view appears, so we can't resolve it during `init`.
    @State private var suggestedLabelName: String?
    
    @State private var isShowingCreateLabelSheet = false
    
    @Query(sort: \TransactionLabel.title) private var availableLabels: [TransactionLabel]
    
    // MARK: - Pre-populated Initial Values based on scanned receipt's information (Optional)
    init(prefilled: ExtractedReceiptData? = nil) {
        _occurredAt     = State(initialValue: prefilled?.occurredAt ?? Date())
        _amount         = State(initialValue: prefilled?.formattedAmount ?? "")
        _selectedType   = State(initialValue: prefilled?.transactionType ?? .outflow)
        _transactionNote = State(initialValue: prefilled?.note ?? "")
        _suggestedLabelName = State(initialValue: prefilled?.suggestedLabelName)
    }
    
    var body: some View {
        Form {
            Section {
                HStack(alignment: .firstTextBaseline) {
                    Text("Rp")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    TextField("0.00", text: $amount)
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.bold)
                        .keyboardType(.decimalPad)
                }
                .padding(.vertical, 4)
                
                Picker("Transaction Type", selection: $selectedType) {
                    ForEach(TransactionType.allCases.filter { $0 != .all }) { type in
                        Text(type.label).tag(type)
                    }
                }
                
            } header: {
                Text("Transaction Details")
            }
            
            Section {
                DatePicker("Occured Date", selection: $occurredAt, displayedComponents: .date)
                    .datePickerStyle(.compact)
                
                Picker("Transaction Label", selection: $selectedLabel) {
                    Text("Select Label")
                        .tag(nil as TransactionLabel?)
                    
                    ForEach(availableLabels) { label in
                        HStack {
                            Image(systemName: label.symbol)
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(label.tint, in: Circle())
                            
                            Text(label.title)
                        }
                        .tag(label as TransactionLabel?)
                    }
                }
                .pickerStyle(.navigationLink)
                
            } header: {
                Text("Classification")
            } footer: {
                Button {
                    isShowingCreateLabelSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: Icon.plus)
                        Text("Missing a label? Create New")
                    }
                    .font(.footnote)
                    .fontWeight(.medium)
                }
                .padding(.top, 6)
            }
            
            Section {
                TextField("Dinner with family, monthly electricity, etc.", text: $transactionNote, axis: .vertical)
                    .lineLimit(1...4)
            } header: {
                Text("Notes")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("New Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    // Move back to TransactionView (The root)
                    router.popToRoot()
                } label: {
                    Image(systemName: Icon.chevronBack)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    guard let label = selectedLabel else { return }
                    
                    viewModel.saveTransaction(
                        occurredAt: occurredAt,
                        amount: Double(amount) ?? 0,
                        type: selectedType,
                        note: transactionNote.isEmpty ? "-" : transactionNote,
                        label: label
                    )
                    
                } label: {
                    Text("Save")
                }
                .disabled(amount.isEmpty || selectedLabel == nil)
            }
        }
        .alert(
            viewModel.message?.isSuccess == true ? "Success" : "Error",
            isPresented: Binding(
                get: { viewModel.message != nil },
                set: { if !$0 { viewModel.message = nil } }
            ),
            presenting: viewModel.message
        ) { message in
            Button {
                if message.isSuccess {
                    router.popToRoot()
                }
            } label: {
                Text("Got it!")
            }
        } message: { message in
            Text(message.text)
        }
        .sheet(isPresented: $isShowingCreateLabelSheet) {
            NewTransactionLabelView(
                viewModel: $viewModel,
                isShowingCreateLabelSheet: $isShowingCreateLabelSheet
            )
            .presentationDetents([.large])
        }
        .onAppear {
            resolveLabel(from: availableLabels)
        }
        .onChange(of: availableLabels) { _, newLabels in
            resolveLabel(from: newLabels)
        }
    }
    
    // MARK: - Private Helpers
    /// Matches the AI-suggested label name against available labels.
    /// Falls back to the first label when no match is found.
    private func resolveLabel(from labels: [TransactionLabel]) {
        guard selectedLabel == nil else { return }
        
        if let suggested = suggestedLabelName, !suggested.isEmpty {
            // Prefer an exact case-insensitive match first,
            // then a partial (contains) match as a fallback.
            let exactMatch = labels.first {
                $0.title.localizedCaseInsensitiveCompare(suggested) == .orderedSame
            }
            let partialMatch = exactMatch ?? labels.first {
                $0.title.localizedCaseInsensitiveContains(suggested) ||
                suggested.localizedCaseInsensitiveContains($0.title)
            }
            selectedLabel = partialMatch ?? labels.first
        } else {
            selectedLabel = labels.first
        }
    }
}

#Preview {
    NavigationStack {
        NewTransactionView()
    }
}
