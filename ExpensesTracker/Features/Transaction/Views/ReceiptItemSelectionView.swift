//
//  ReceiptItemSelectionView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 11/09/26.
//

import SwiftUI

struct ReceiptItemSelectionView: View {
    let detail: ExtractedReceiptDetail
    let onConfirmShare: (Double, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedItemIds: Set<UUID> = []
    @State private var customQuantities: [UUID: Int] = [:]

    private var breakdown: (
        selectedSubtotal: Double,
        proportionalTax: Double,
        proportionalService: Double,
        proportionalDiscount: Double,
        totalShare: Double
    ) {
        detail.breakdown(for: selectedItemIds, customQuantities: customQuantities)
    }

    private var allSelected: Bool {
        !detail.items.isEmpty && selectedItemIds.count == detail.items.count
    }

    private var selectedItemsSummaryNote: String {
        detail.summaryNote(for: selectedItemIds, customQuantities: customQuantities)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header overview
                VStack(spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Select & Adjust Items")
                                .font(.headline)
                            Text("Full Receipt Total: \(detail.grandTotal, format: .currency(code: "IDR"))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button(allSelected ? "Deselect All" : "Select All") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if allSelected {
                                    selectedItemIds.removeAll()
                                } else {
                                    selectedItemIds = Set(detail.items.map(\.id))
                                }
                            }
                        }
                        .font(.caption)
                        .fontWeight(.semibold)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    Divider()
                }

                // Item list
                if detail.items.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "cart.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No specific items detected")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("You can still use the full receipt amount directly.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(detail.items) { item in
                            let isSelected = selectedItemIds.contains(item.id)
                            let currentQty = customQuantities[item.id] ?? item.quantity
                            let rowTotal = item.price * Double(max(1, currentQty))

                            HStack(spacing: 12) {
                                // Checkbox
                                Button {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                        if isSelected {
                                            selectedItemIds.remove(item.id)
                                        } else {
                                            selectedItemIds.insert(item.id)
                                        }
                                    }
                                } label: {
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.6))
                                }
                                .buttonStyle(.plain)

                                // Item Info
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.name)
                                        .font(.body)
                                        .fontWeight(isSelected ? .semibold : .regular)
                                        .foregroundStyle(.primary)

                                    Text(item.price, format: .currency(code: "IDR"))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                // Quantity Stepper (when selected)
                                if isSelected {
                                    HStack(spacing: 6) {
                                        Button {
                                            if currentQty > 1 {
                                                customQuantities[item.id] = currentQty - 1
                                            }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.body)
                                                .foregroundStyle(currentQty > 1 ? Color.accentColor : Color.secondary.opacity(0.3))
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(currentQty <= 1)

                                        Text("\(currentQty)")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .frame(minWidth: 20, alignment: .center)

                                        Button {
                                            customQuantities[item.id] = currentQty + 1
                                        } label: {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.body)
                                                .foregroundStyle(Color.accentColor)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color(.tertiarySystemBackground))
                                    .clipShape(Capsule())
                                }

                                // Total for item
                                Text(rowTotal, format: .currency(code: "IDR"))
                                    .font(.subheadline)
                                    .fontWeight(isSelected ? .bold : .medium)
                                    .foregroundStyle(isSelected ? .primary : .secondary)
                                    .frame(minWidth: 70, alignment: .trailing)
                            }
                            .padding(.vertical, 4)
                            .listRowBackground(
                                isSelected
                                    ? Color.accentColor.opacity(0.08)
                                    : Color.clear
                            )
                        }
                    }
                    .listStyle(.plain)
                }

                // Bottom summary & Action
                VStack(spacing: 12) {
                    Divider()

                    // Breakdown details if extra charges exist
                    if breakdown.selectedSubtotal > 0 && (detail.tax > 0 || detail.serviceCharge > 0 || detail.discount > 0) {
                        VStack(spacing: 4) {
                            HStack {
                                Text("Selected Items Subtotal")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(breakdown.selectedSubtotal, format: .currency(code: "IDR"))
                            }
                            .font(.caption)

                            if breakdown.proportionalTax > 0 {
                                HStack {
                                    Text("Proportional Tax / PPN")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("+\(breakdown.proportionalTax, format: .currency(code: "IDR"))")
                                        .foregroundStyle(.secondary)
                                }
                                .font(.caption)
                            }

                            if breakdown.proportionalService > 0 {
                                HStack {
                                    Text("Proportional Service Charge")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Text("+\(breakdown.proportionalService, format: .currency(code: "IDR"))")
                                        .foregroundStyle(.secondary)
                                }
                                .font(.caption)
                            }

                            if breakdown.proportionalDiscount > 0 {
                                HStack {
                                    Text("Proportional Discount")
                                        .foregroundStyle(.green)
                                    Spacer()
                                    Text("-\(breakdown.proportionalDiscount, format: .currency(code: "IDR"))")
                                        .foregroundStyle(.green)
                                }
                                .font(.caption)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Total Share Banner
                    HStack(alignment: .lastTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Your Share")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                            Text("\(selectedItemIds.count) of \(detail.items.count) item\(detail.items.count == 1 ? "" : "s") selected")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()

                        Text(breakdown.totalShare, format: .currency(code: "IDR"))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal)

                    // Confirm button
                    Button {
                        let finalAmount = breakdown.totalShare
                        let note = selectedItemsSummaryNote
                        dismiss()
                        onConfirmShare(finalAmount, note)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Use My Share (\(breakdown.totalShare, format: .currency(code: "IDR")))")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedItemIds.isEmpty || breakdown.totalShare <= 0)
                    .padding(.horizontal)
                    .padding(.bottom, 6)
                }
                .background(Color(.secondarySystemBackground))
            }
            .navigationTitle("Split by Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if selectedItemIds.isEmpty {
                    selectedItemIds = Set(detail.items.map(\.id))
                }
                for item in detail.items {
                    if customQuantities[item.id] == nil {
                        customQuantities[item.id] = item.quantity
                    }
                }
            }
        }
    }
}
