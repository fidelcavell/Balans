//
//  CreatePreferenceView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 05/07/26.
//

import SwiftUI

struct CreatePreferenceView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @State private var viewModel: SettingsViewModel = SettingsViewModel()
    
    @State private var name: String = ""
    @State private var monthlySpendingLimit: Double = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // MARK: - Header
                VStack(spacing: 8) {
                    Text("Welcome")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.primary)
                    
                    Text("Let's set up your personal preferences to get started.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 20)
                
                // MARK: - Input Form
                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your name", text: $name)
                                .padding()
                                .background(Color(.systemGroupedBackground))
                                .cornerRadius(12)
                        }
                        .padding(8)
                        
                    } header: {
                        Text("Personal Data")
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Spending Limit")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Text("Rp")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                    
                                    TextField("", value: $monthlySpendingLimit, format: .number)
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(maxWidth: 110) // Prevents the layout from breaking
                                }
                            }
                            
                            Slider(value: $monthlySpendingLimit, in: 0...20000000, step: 100000)
                                .tint(.blue)
                            
                            HStack {
                                Text("Rp 0").font(.footnote).foregroundColor(.secondary)
                                Spacer()
                                Text("Rp 20.000.000").font(.footnote).foregroundColor(.secondary)
                            }
                        }
                        .padding(8)
                    } header: {
                        Text("Monthly Spending Limit")
                    }
                }
                .padding(.horizontal, 8)
                
                Spacer()
                
                // MARK: - Action Button
                Button(action: {
                    viewModel.addUpdatePreference(
                        id: nil,
                        name: name,
                        monthlySpendingLimit: Int(monthlySpendingLimit)
                    )
                    
                    print("Saved: \(name) with limit $\(monthlySpendingLimit)")
                }) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(name.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(14)
                }
                .disabled(name.isEmpty)
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .alert(item: $viewModel.message) { message in
                Alert(
                    title: Text(message.isSuccess ? "Success" : "Error"),
                    message: Text(message.text),
                    dismissButton: .default(Text("Got it!")) {
                        if message.isSuccess {
                            hasOnboarded = true
                        }
                    }
                )
            }
        }
    }
}

#Preview {
    CreatePreferenceView()
}
