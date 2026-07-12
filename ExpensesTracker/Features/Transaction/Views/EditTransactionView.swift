//
//  EditTransactionView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 09/07/26.
//

import SwiftUI
import SwiftData

struct EditTransactionView: View {
    @Binding var viewModel: TransactionViewModel
    @Binding var isShowingEditSheet: Bool
    var selectedTransaction: Transaction
    
    @State private var amount: Double = 0.0
    @State private var selectedType: TransactionType = .outflow
    @State private var selectedLabel: TransactionLabel?
    @State private var occurredAt: Date = Date()
    @State private var note: String = ""
    
    @Query(sort: \TransactionLabel.title) private var availableLabels: [TransactionLabel]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Amount", value: $amount, format: .currency(code: "IDR"))
                        .keyboardType(.decimalPad)
                        .font(.title2)
                        .bold()
                } header: {
                    Text("Transaction Amount")
                }
                
                Section {
                    Picker("Transaction Type", selection: $selectedType) {
                        ForEach(TransactionType.allCases) { type in
                            Text(type.label).tag(type)
                        }
                    }
                    
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
                }
                
                Section {
                    DatePicker("Occured Date", selection: $occurredAt, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    
                } header: {
                    Text("Date")
                }
                
                Section {
                    TextField("Add a note...", text: $note, axis: .vertical)
                        .lineLimit(3...5)
                } header: {
                    Text("Notes")
                }
            }
            .navigationTitle("Update Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        isShowingEditSheet = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.updateTransaction(
                            id: selectedTransaction.id,
                            occurredAt: occurredAt,
                            amount: amount,
                            type: selectedType,
                            note: note,
                            label: selectedLabel
                        )
                        
                        isShowingEditSheet = false
                    } label: {
                        Text("Save")
                    }
                }
            }
            .onAppear {
                amount = selectedTransaction.amount
                selectedType = selectedTransaction.type
                selectedLabel = selectedTransaction.label
                occurredAt = selectedTransaction.occurredAt
                note = selectedTransaction.note
            }
        }
    }
}

#Preview {
    EditTransactionView(
        viewModel: .constant(TransactionViewModel()),
        isShowingEditSheet: .constant(false),
        selectedTransaction: Transaction(occurredAt: Date(), amount: 0, type: .outflow)
    )
}
