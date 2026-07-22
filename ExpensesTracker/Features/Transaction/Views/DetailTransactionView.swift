//
//  DetailTransactionView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 09/07/26.
//

import SwiftUI
import SwiftData

struct DetailTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TransactionViewModel = TransactionViewModel()
    
    var selectedTransaction: Transaction
    
    @State private var isShowingDeleteAlert = false
    @State private var isShowingEditSheet = false
    
    var body: some View {
        Form {
            // MARK: - Transaction Amount and Type
            Section {
                VStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: selectedTransaction.label?.symbol ?? Icon.question)
                        Text(selectedTransaction.label?.title ?? "No Category")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(selectedTransaction.label?.tint ?? .gray)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill((selectedTransaction.label?.tint ?? .gray).opacity(0.15))
                    )
                    
                    Text(selectedTransaction.amount.formatted(.currency(code: "IDR")))
                        .font(.system(size: 34, weight: .bold, design: .monospaced))
                        .foregroundStyle(selectedTransaction.type == .inflow ? Color.green : Color.red)
                    
                    Text(selectedTransaction.type == .inflow ? "Income" : "Expense")
                        .font(.caption)
                        .fontWeight(.bold)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                        .tracking(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            
            // MARK: - Transaction Meta Data
            Section {
                HStack(spacing: 16) {
                    Image(systemName: Icon.calendar)
                        .font(.system(size: 16))
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.blue)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Transaction occured at ")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(selectedTransaction.occurredAt.formatted(date: .long, time: .omitted))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
                .padding(.vertical, 2)
                
            } header: {
                Text("Additional Data")
            }
            
            // MARK: - Transaction Notes
            Section {
                Text(selectedTransaction.note.isEmpty || selectedTransaction.note == "-" ? "No additional details provided for this transaction." : selectedTransaction.note)
                    .font(.body)
                    .foregroundStyle(selectedTransaction.note.isEmpty || selectedTransaction.note == "-" ? .secondary : .primary)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                
            } header: {
                Text("Notes")
            }
        }
        .navigationTitle("Transaction Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isShowingEditSheet = true
                } label: {
                    Image(systemName: Icon.editButton)
                }
                
                Button(role: .destructive) {
                    isShowingDeleteAlert = true
                } label: {
                    Image(systemName: Icon.deletebutton)
                        .foregroundStyle(.red)
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            EditTransactionView(
                viewModel: $viewModel,
                isShowingEditSheet: $isShowingEditSheet,
                selectedTransaction: selectedTransaction
            )
            .presentationDetents([.large])
        }
        .alert("Delete Transaction?", isPresented: $isShowingDeleteAlert) {
            Button("Delete", role: .destructive) {
                viewModel.deleteRecord(selectedTransaction)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to permanently delete this transaction? This action cannot be undone.")
        }
    }
}
