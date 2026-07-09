//
//  NewTransactionLabelView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 07/07/26.
//

import SwiftUI

struct NewTransactionLabelView: View {
    @Binding var viewModel: TransactionViewModel
    @Binding var isShowingCreateLabelSheet: Bool
    
    @State private var title: String = ""
    @State private var selectedSymbol: String = "tag.fill"
    @State private var selectedColor: Color = .blue
    @State private var hexColorString: String = "0000FF" // Stores the "FFFFFF" format as default
    
    let availableSymbols = ["tag.fill", "cart.fill", "creditcard.fill", "bag.fill", "banknote.fill"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("e.g., Groceries", text: $title)
                } header: {
                    Text("Transaction Label Title || \(viewModel.message?.text ?? "MSG")")
                }
                
                Section(header: Text("Select Icon")) {
                    Picker("Symbol", selection: $selectedSymbol) {
                        ForEach(availableSymbols, id: \.self) { symbol in
                            HStack {
                                Image(systemName: symbol)
                                Text(symbol.replacingOccurrences(of: ".fill", with: "").capitalized)
                            }
                            .tag(symbol)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section(header: Text("Select Color")) {
                    ColorPicker("Label Color", selection: $selectedColor, supportsOpacity: false)
                        .onChange(of: selectedColor) { _, newColor in
                            // Convert the new Color to a Hex String automatically
                            if let hex = newColor.toHex() {
                                hexColorString = hex
                            }
                        }
                    
                    HStack {
                        Text("Hex Code:")
                        Spacer()
                        Text("#\(hexColorString)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Preview")) {
                    HStack(spacing: 12) {
                        Image(systemName: selectedSymbol)
                            .foregroundColor(selectedColor)
                            .font(.title2)
                        Text(title.isEmpty ? "Preview Title" : title)
                            .font(.headline)
                    }
                }
                
                Button {
                    viewModel.saveTransactionLabel(
                        title: title,
                        symbol: selectedSymbol,
                        hexColor: hexColorString
                    )
                } label: {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.blue)
            }
            .navigationTitle("New Transaction Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        isShowingCreateLabelSheet = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .alert(
                viewModel.message?.isSuccess == true ? "Success" : "Error",
                isPresented: Binding(
                    get: { viewModel.message != nil },
                    set: { if !$0 { viewModel.message = nil } }
                ),
                presenting: viewModel.message
            ) { message in
                Button {
                    if message.isSuccess {
                        isShowingCreateLabelSheet = false
                    }
                } label: {
                    Text("Got it!")
                }
            } message: { message in
                Text(message.text)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NewTransactionLabelView(
            viewModel: .constant(TransactionViewModel()),
            isShowingCreateLabelSheet: .constant(false)
        )
    }
}
