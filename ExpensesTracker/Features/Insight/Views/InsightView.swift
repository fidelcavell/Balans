//
//   InsightView.swift
//   ExpensesTracker
//
//   Created by Fidel Fausta Cavell on 02/07/26.
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Local Data Model
struct ExpenseLabel: Identifiable {
    let id = UUID()
    let label: TransactionLabel
    let amount: Double
}

struct MonthlyTransaction: Identifiable {
    let id = UUID()
    let year: Int
    let monthName: String
    let labels: [ExpenseLabel]
    let totalIncome: Double
    let totalExpenses: Double
}

struct InsightView: View {
    @State private var viewModel = InsightViewModel()
    
    @State private var selectedDate = Date()
    @State private var selectedSector: String? = nil
    @State private var isDatePickerPresented = false
    
    @State private var selectedChartTab: Int = 0
    
    @Query(sort: \Transaction.occurredAt, order: .reverse) private var transactions: [Transaction]
    
    // MARK: - Computed Properties
    private var selectedYear: Int {
        get {
            Calendar.current.component(.year, from: selectedDate)
        }
        set {
            var components = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second], from: selectedDate)
            components.year = newValue
            if let newDate = Calendar.current.date(from: components) {
                selectedDate = newDate
            }
        }
    }
    
    private var selectedMonth: String {
        get {
            let monthInt = Calendar.current.component(.month, from: selectedDate)
            return Calendar.current.shortMonthSymbols[monthInt - 1]
        }
        set {
            let shortMonths = Calendar.current.shortMonthSymbols
            if let monthIndex = shortMonths.firstIndex(of: newValue) {
                var components = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second], from: selectedDate)
                components.month = monthIndex + 1
                if let newDate = Calendar.current.date(from: components) {
                    selectedDate = newDate
                }
            }
        }
    }
    
    /// Pulls distinct years safely from all persisted Transaction logs
    private var availableYears: [Int] {
        let years = transactions.map { Calendar.current.component(.year, from: $0.occurredAt) }
        let distinct = Array(Set(years)).sorted(by: >)
        return distinct.isEmpty ? [Calendar.current.component(.year, from: Date())] : distinct
    }
    
    /// Filters transactions down to the currently selected year
    private var filteredTransactionByYear: [Transaction] {
        transactions.filter { Calendar.current.component(.year, from: $0.occurredAt) == selectedYear }
    }
    
    /// Filters transactions down to the currently selected month
    private var filteredTransactionByMonth: [Transaction] {
        filteredTransactionByYear.filter { transaction in
            let monthInt = Calendar.current.component(.month, from: transaction.occurredAt)
            let monthName = Calendar.current.shortMonthSymbols[monthInt - 1]
            return monthName == selectedMonth
        }
    }
    
    /// Filters transactions down to the currently selected month and groups them into ExpenseLabels
    private var filteredExpenseByMonth: [ExpenseLabel] {
        // Filter the year's transactions down to the selected month and ensure they are outflows (expenses)
        let monthlyExpenses = filteredTransactionByYear.filter { transaction in
            let monthInt = Calendar.current.component(.month, from: transaction.occurredAt)
            let monthName = Calendar.current.shortMonthSymbols[monthInt - 1]
            
            // Match both the month name string and ensure it's an outflow expense
            return monthName == selectedMonth && transaction.type == .outflow
        }
        
        // Group the filtered transactions by their unique TransactionLabel
        let groupedByLabel = Dictionary(grouping: monthlyExpenses, by: { $0.label })
        
        return groupedByLabel.compactMap { (label, transactions) -> ExpenseLabel? in
            guard let label = label else { return nil }
            return ExpenseLabel(
                label: label,
                amount: transactions.reduce(0) { $0 + $1.amount }
            )
        }
        .sorted(by: { $0.amount > $1.amount })
    }
    
    /// Groups the filtered transactions of the selected month into a single MonthlyTransaction container
    private var currentMonthTransaction: MonthlyTransaction? {
        guard !filteredExpenseByMonth.isEmpty else { return nil }
        
        let totalIncome = filteredTransactionByMonth.filter { $0.type == .inflow }.reduce(0) { $0 + $1.amount }
        let totalExpenses = filteredTransactionByMonth.filter { $0.type == .outflow }.reduce(0) { $0 + $1.amount }
        
        return MonthlyTransaction(
            year: selectedYear,
            monthName: selectedMonth,
            labels: filteredExpenseByMonth,
            totalIncome: totalIncome,
            totalExpenses: totalExpenses
        )
    }
    
    /// Call the total transaction's expense by selected month
    private var totalTransactionExpenseByMonth: Double {
        currentMonthTransaction?.totalExpenses ?? 0
    }
    
    /// Safe shorthand to extract sorted expense labels for the current month layout
    private var currentMonthLabels: [ExpenseLabel] {
        currentMonthTransaction?.labels ?? []
    }
    
    /// Extracts the top 3 highest spending category nodes for trend highlighting
    private var topSpendingCategories: [ExpenseLabel] {
        Array(currentMonthLabels.prefix(3))
    }
    
    /// ...
    private var activeCategory: ExpenseLabel? {
        currentMonthTransaction?.labels.first(where: { $0.label.title == selectedSector })
    }
    
    /// Group the yearly transaction data
    private var yearlyTrendData: [MonthlyTransaction] {
        let calendar = Calendar.current
        let shortMonths = calendar.shortMonthSymbols
        
        // Group raw data: [String: [Transaction]]
        let groupedByMonth = Dictionary(grouping: filteredTransactionByYear) { transaction in
            let monthInt = calendar.component(.month, from: transaction.occurredAt)
            return shortMonths[monthInt - 1]
        }
        
        // Map directly into the structural array format your view requires
        let allMonthsData = shortMonths.map { monthName -> MonthlyTransaction in
            let transactionsForThisMonth = groupedByMonth[monthName] ?? []
            
            // Isolate outflows (expenses)
            let monthlyExpenses = transactionsForThisMonth.filter { $0.type == .outflow }
            
            let groupedByLabel = Dictionary(grouping: monthlyExpenses, by: { $0.label })
            let expenseLabels = groupedByLabel.compactMap { (label, txs) -> ExpenseLabel? in
                guard let label = label else { return nil }
                return ExpenseLabel(label: label, amount: txs.reduce(0) { $0 + $1.amount })
            }
            
            // Sum up inflows (income)
            let incomeSum = transactionsForThisMonth
                .filter { $0.type == .inflow }
                .reduce(0.0) { $0 + $1.amount }
            
            // Sum up outflows (expenses) directly from raw transactions
            let expenseSum = monthlyExpenses
                .reduce(0.0) { $0 + $1.amount }
            
            // Neatly returns the MonthlyTransaction container matching your exact structure
            return MonthlyTransaction(
                year: selectedYear,
                monthName: monthName,
                labels: expenseLabels,
                totalIncome: incomeSum,
                totalExpenses: expenseSum
            )
        }
        
        let hasData = allMonthsData.contains { $0.totalIncome > 0 || $0.totalExpenses > 0 }
        return hasData ? allMonthsData : []
    }
    
    /// Calculate the total yearly income
    private var totalYearlyIncome: Double {
        yearlyTrendData.reduce(0) { $0 + $1.totalIncome }
    }
    
    /// Calculate the total yearly expense
    private var totalYearlyExpenses: Double {
        yearlyTrendData.reduce(0) { $0 + $1.totalExpenses }
    }
    
    /// Calculate the yearly net savings
    private var yearlyNetSavings: Double {
        totalYearlyIncome - totalYearlyExpenses
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        SwipeableCard
                        
                        AIInsightCardView(
                            report: viewModel.report,
                            isLoading: viewModel.isLoading,
                            isUnavailable: viewModel.isUnavailable,
                            onRefresh: {
                                Task {
                                    await viewModel.generateInsight(
                                        currentMonth: currentMonthTransaction,
                                        yearlyTrendData: yearlyTrendData,
                                        selectedYear: selectedYear
                                    )
                                }
                            }
                        )
                        
                        BreakdownCategoriesCardView(
                            currentMonthLabels: currentMonthLabels,
                            totalTransactionExpenseByMonth: totalTransactionExpenseByMonth,
                            selectedSector: $selectedSector
                        )
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
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
            }
            // Reset the report whenever the user picks a different month/year
            .onChange(of: selectedDate) {
                viewModel.report = nil
                viewModel.isUnavailable = false
            }
            .alert(item: $viewModel.message) { message in
                Alert(title: Text(message.isSuccess ? "Success" : "Error"), message: Text(message.text))
            }
        }
    }
    
    // MARK: - Swipeable Card Component
    private var SwipeableCard: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedChartTab == 0 ? "Expense Distribution" : "Your Balances Trend in \(selectedYear, format: .number.grouping(.never))")
                        .font(.headline)
                    Text(selectedChartTab == 0 ? "Interactive category breakdown" : "Yearly overview of savings trajectory")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: Icon.pieChart)
                        .font(.footnote)
                        .padding(6)
                        .background(selectedChartTab == 0 ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
                        .foregroundStyle(selectedChartTab == 0 ? .white : .secondary)
                        .clipShape(Circle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedChartTab = 0 }
                        }
                    
                    Image(systemName: Icon.xyAxisLineChart)
                        .font(.footnote)
                        .padding(6)
                        .background(selectedChartTab == 1 ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
                        .foregroundStyle(selectedChartTab == 1 ? .white : .secondary)
                        .clipShape(Circle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedChartTab = 1 }
                        }
                }
                .padding(4)
                .background(Color(.systemGroupedBackground))
                .clipShape(Capsule())
            }
            .padding([.top, .horizontal], 16)
            
            TabView(selection: $selectedChartTab) {
                DonutChartView(
                    currentMonthTransaction: currentMonthTransaction,
                    selectedSector: $selectedSector,
                    totalTransactionExpenseByMonth: totalTransactionExpenseByMonth,
                    activeCategory: activeCategory
                )
                .tag(0)
                .padding(.horizontal, 16)
                
                YearlyTrendChartView(
                    yearlyTrendData: yearlyTrendData,
                    totalYearlyIncome: totalYearlyIncome,
                    totalYearlyExpenses: totalYearlyExpenses,
                    yearlyNetSavings: yearlyNetSavings
                )
                .tag(1)
                .padding(.horizontal, 16)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 240)
        }
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }
}
