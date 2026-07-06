//
//  SettingsView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 01/07/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel = SettingsViewModel()
    
    @State private var name: String = ""
    @State private var currentSpending: Double = 0
    @State private var monthlySpendingLimit: Double = 0
    
    @State private var isEditing = false
    
    @Query private var preferences: [Preference]
    var preference: Preference {
        preferences.first!
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Name", value: preference.name)
                } header: {
                    Text("Personal Data")
                }
                
                Section {
                    LabeledContent("Current Spending", value: preference.currentSpending.formatted(.currency(code: "IDR")))
                    LabeledContent("Monthly Spending Limit", value: preference.monthlySpendingLimit.formatted(.currency(code: "IDR")))
                } header: {
                    Text("Budgeting Details")
                }
                
                Section {
                    Toggle(isOn: .constant(true)) {
                        Text("Notification")
                    }
                } header: {
                    Text("Additional Preferences")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isEditing = true
                    } label: {
                        Text("Edit")
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                VStack {
                    Text("Editting Your Personal Preferences")
                }
                .presentationDetents([.fraction(0.65)])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

#Preview {
    SettingsView()
}
