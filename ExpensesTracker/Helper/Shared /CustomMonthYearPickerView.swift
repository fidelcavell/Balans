//
//  CustomMonthYearPickerView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 02/07/26.
//

import SwiftUI

struct CustomMonthYearPickerView: View {
    @Binding var selectedDate: Date
    
    let months = Calendar.current.shortMonthSymbols
    let years = Array(2020...2030)
    
    private var currentMonth: Binding<Int> {
        Binding(
            get: { Calendar.current.component(.month, from: selectedDate) },
            set: { updateDate(month: $0, year: nil) }
        )
    }
    
    private var currentYear: Binding<Int> {
        Binding(
            get: { Calendar.current.component(.year, from: selectedDate) },
            set: { updateDate(month: nil, year: $0) }
        )
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Picker("Month", selection: currentMonth) {
                ForEach(1...12, id: \.self) { month in
                    Text(months[month - 1]).tag(month)
                }
            }
            .pickerStyle(.wheel)
            
            Picker("Year", selection: currentYear) {
                ForEach(years, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            .pickerStyle(.wheel)
        }
        .frame(height: 120)
    }
    
    private func updateDate(month: Int?, year: Int?) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.day, .month, .year, .hour, .minute, .second], from: selectedDate)
        
        if let month = month { components.month = month }
        if let year = year { components.year = year }
        
        if let newDate = calendar.date(from: components) {
            selectedDate = newDate
        }
    }
}

#Preview {
    CustomMonthYearPickerView(
        selectedDate: .constant(Date())
    )
}
