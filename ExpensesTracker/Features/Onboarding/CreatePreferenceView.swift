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
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Let's set up your personal preferences to get started.")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 16)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Personal Data")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your name", text: $name)
                                .padding()
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                )
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Monthly Spending Limit")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Spending Limit")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            // Live IDR Value Display
                            Text(monthlySpendingLimit, format: .currency(code: "IDR").precision(.fractionLength(0)))
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Slider(value: $monthlySpendingLimit, in: 0...20000000, step: 100000)
                                .tint(.blue)
                            
                            HStack {
                                Text("Rp 0").font(.footnote).foregroundColor(.secondary)
                                Spacer()
                                Text("Rp 20.000.000").font(.footnote).foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.addUpdatePreference(
                            id: nil,
                            name: name,
                            monthlySpendingLimit: Int(monthlySpendingLimit)
                        )
                        
                        print("Saved: \(name) with limit IDR \(monthlySpendingLimit)")
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
                    .padding(.vertical, 24)
                }
                .padding(.horizontal, 32)
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
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}

#Preview {
    CreatePreferenceView()
}
