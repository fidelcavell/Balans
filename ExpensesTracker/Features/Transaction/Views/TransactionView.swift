//
//  TransactionView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 30/06/26.
//

import SwiftUI
import SwiftData

struct TransactionView: View {
    @Environment(Router.self) private var router
    @State private var viewModel: TransactionViewModel = TransactionViewModel()
    
    @State private var selectedType: TransactionType = .all
    @State private var selectedDate = Date()
    @State private var isDatePickerPresented = false
    
    @Query(sort: \Transaction.occurredAt, order: .reverse) private var transactions: [Transaction]
    @Query private var preferences: [Preference]
    var preference: Preference {
        preferences.first!
    }
    
    var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let filterComponents = calendar.dateComponents([.month, .year], from: selectedDate)
        
        return transactions.filter { transaction in
            guard transaction.type == selectedType || selectedType == .all else { return false }
            let tComponents = calendar.dateComponents([.month, .year], from: transaction.occurredAt)
            
            return tComponents.month == filterComponents.month && tComponents.year == filterComponents.year
        }
    }
    
    // Computed property to group transactions by calendar day
    var dateGroupedTransactions: [(key: Date, value: [Transaction])] {
        let calendar = Calendar.current
        
        // Group transactions by the start of their date (ignoring hours, minutes, seconds)
        let grouped = Dictionary(grouping: filteredTransactions) { transaction in
            calendar.startOfDay(for: transaction.occurredAt)
        }
        
        // Sort keys in descending order (newest dates first)
        return grouped.sorted { $0.key > $1.key }
    }
    
    var currentMonthIncome: Double {
        let calendar = Calendar.current
        let filterComponents = calendar.dateComponents([.month, .year], from: selectedDate)
        
        return transactions.lazy
            .filter { transaction in
                guard transaction.type == .inflow else { return false }
                let tComponents = calendar.dateComponents([.month, .year], from: transaction.occurredAt)
                
                return tComponents.month == filterComponents.month && tComponents.year == filterComponents.year
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    var currentMonthExpense: Double {
        let calendar = Calendar.current
        let filterComponents = calendar.dateComponents([.month, .year], from: selectedDate)
        
        return transactions.lazy
            .filter { transaction in
                guard transaction.type == .outflow else { return false }
                let tComponents = calendar.dateComponents([.month, .year], from: transaction.occurredAt)
                
                return tComponents.month == filterComponents.month && tComponents.year == filterComponents.year
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        @Bindable var router = router
        
        NavigationStack(path: $router.path) {
            VStack(spacing: 0) {
                MonthlySpendingCardView(
                    totalIncome: currentMonthIncome,
                    totalExpense: currentMonthExpense,
                    monthlySpendingLimit: Double(preference.monthlySpendingLimit)
                )
                .padding(.top, 12)
                
                HStack {
                    Text("Transaction List")
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                ZStack {
                    if filteredTransactions.isEmpty {
                        VStack(spacing: 12) {
                            Spacer()
                            LottieAnimationView(fileName: "empty_box")
                                .frame(width: 250, height: 250)
                            Text("No Transactions")
                                .font(.title3)
                                .fontWeight(.bold)
                            Text("No transactions found for this selection.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 16) {
                                ForEach(dateGroupedTransactions, id: \.key) { date, transactions in
                                    VStack(alignment: .leading, spacing: 8) {
                                        // Date Header
                                        Text(date, format: .dateTime.day().month(.wide).year())
                                            .font(.footnote)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.secondary)
                                            .padding(.horizontal)
                                        
                                        // Transactions for this specific date
                                        VStack(spacing: 8) {
                                            ForEach(transactions) { transaction in
                                                TransactionCardView(transaction: transaction)
                                                    .scrollTransition(.animated, axis: .vertical) { content, phase in
                                                        content
                                                            .opacity(phase.isIdentity ? 1.0 : 0.6)
                                                            .scaleEffect(phase.isIdentity ? 1.0 : 0.96)
                                                            .offset(y: phase.isIdentity ? 0 : (phase == .topLeading ? -8 : 8))
                                                    }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.top, 4)
                            .padding(.bottom, 32)
                        }
                    }
                    
                    FABView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isDatePickerPresented.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedDate.formatted(.dateTime.month(.abbreviated).year()))
                            
                            Image(systemName: Icon.chevronDown)
                                .font(.caption2)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                    }
                    .popover(isPresented: $isDatePickerPresented) {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer()
                                Button("Done") {
                                    isDatePickerPresented = false
                                }
                                .fontWeight(.semibold)
                                .font(.subheadline)
                            }
                            .padding([.top, .horizontal], 16)
                            
                            CustomMonthYearPickerView(selectedDate: $selectedDate)
                                .padding(.bottom, 8)
                        }
                        .presentationCompactAdaptation(.popover)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Transaction Type", selection: $selectedType) {
                            ForEach(TransactionType.allCases) { type in
                                Text(type.label).tag(type)
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedType.label)
                            Image(systemName: Icon.chevronDown)
                                .font(.caption2)
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                    }
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .newTransaction:
                    NewTransactionView()
                case .camera:
                    CameraView()
                case .detailTransaction(let transaction):
                    DetailTransactionView(selectedTransaction: transaction)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        TransactionView()
            .environment(Router())
    }
}
