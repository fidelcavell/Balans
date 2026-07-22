//
//  EditPreferenceView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 06/07/26.
//

import SwiftUI

struct EditPreferenceView: View {
    @Binding var viewModel: SettingsViewModel
    @Binding var isEditing: Bool
    var currentPreference: Preference
    
    @State private var name: String = ""
    @State private var monthlySpendingLimit: Double = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Enter your name", text: $name)
                    
                } header: {
                    Text("Name")
                }
                
                Section {
                    HStack(spacing: 8) {
                        Text("Rp")
                            .foregroundColor(.secondary)
                        
                        TextField("0", value: $monthlySpendingLimit, format: .number)
                            .keyboardType(.numberPad)
                    }
                } header: {
                    Text("Monthly Spending Limit")
                }
                
                Button {
                    viewModel.addUpdatePreference(
                        id: currentPreference.id,
                        name: name,
                        monthlySpendingLimit: Int(monthlySpendingLimit)
                    )
                } label: {
                    Text("Update")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.blue)
            }
            .navigationTitle("Your Data Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        isEditing = false
                    } label: {
                        Image(systemName: Icon.closeMark)
                    }
                }
            }
            .alert(item: $viewModel.message) { message in
                Alert(
                    title: Text(message.isSuccess ? "Success" : "Error"),
                    message: Text(message.text),
                    dismissButton: .default(Text("Got it!")) {
                        if message.isSuccess {
                            isEditing = false
                        }
                    }
                )
            }
            .onAppear {
                name = currentPreference.name
                monthlySpendingLimit = Double(currentPreference.monthlySpendingLimit)
            }
        }
    }
}

#Preview {
    EditPreferenceView(
        viewModel: .constant(SettingsViewModel()),
        isEditing: .constant(true),
        currentPreference: Preference(name: "Deryl")
    )
}
