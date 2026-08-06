//
//  SettingsView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 01/07/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SettingsViewModel = SettingsViewModel()
    
    @State private var isEditing: Bool = false
    
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
                    LabeledContent("Monthly Spending Limit", value: preference.monthlySpendingLimit.formatted(.currency(code: "IDR")))
                } header: {
                    Text("Budgeting Details")
                }
                
                Section {
                    Toggle(isOn: $viewModel.isNotificationEnabled) {
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
                EditPreferenceView(
                    viewModel: $viewModel,
                    isEditing: $isEditing,
                    currentPreference: preference
                )
                .presentationDetents([.medium])
            }
        }
    }
}

#Preview {
    SettingsView()
}
