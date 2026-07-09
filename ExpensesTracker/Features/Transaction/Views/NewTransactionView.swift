//
//  NewTransactionView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 30/06/26.
//

import SwiftUI
import SwiftData

struct NewTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TransactionViewModel = TransactionViewModel()
    
    @State private var occurredAt: Date = Date()
    @State private var amount: String = ""
    @State private var selectedType: TransactionType = .outflow
    @State private var selectedLabel: TransactionLabel?
    @State private var transactionNote: String = ""
    
    @State private var isShowingCreateLabelSheet = false
    
    @Query(sort: \TransactionLabel.title) private var availableLabels: [TransactionLabel]
    
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
                    ForEach(TransactionType.allCases) { type in
                        Text(type.label).tag(type)
                    }
                }
                .pickerStyle(.navigationLink)
                
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
                        Image(systemName: "plus.circle.fill")
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
                    dismiss()
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
            if selectedLabel == nil {
                selectedLabel = availableLabels.first
            }
        }
        .onChange(of: availableLabels) { _, newLabels in
            if selectedLabel == nil {
                selectedLabel = newLabels.first
            }
        }
    }
}

#Preview {
    NavigationStack {
        NewTransactionView()
    }
}
