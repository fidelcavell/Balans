//
//  ExtractedReceiptDetail.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 11/09/26.
//

import Foundation

public struct ExtractedReceiptDetail: Sendable, Codable {
    public var items: [ExtractedReceiptItem]
    public var subtotal: Double
    public var tax: Double
    public var serviceCharge: Double
    public var discount: Double
    public var grandTotal: Double

    public init(
        items: [ExtractedReceiptItem] = [],
        subtotal: Double = 0,
        tax: Double = 0,
        serviceCharge: Double = 0,
        discount: Double = 0,
        grandTotal: Double = 0
    ) {
        self.items = items
        self.subtotal = subtotal
        self.tax = tax
        self.serviceCharge = serviceCharge
        self.discount = discount
        self.grandTotal = grandTotal
    }

    /// Computed total of all items in the receipt
    public var calculatedItemsSubtotal: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }

    /// Effective base subtotal for ratio calculation: prefer explicit subtotal if > 0, otherwise sum of items
    public var effectiveSubtotal: Double {
        if subtotal > 0 {
            return subtotal
        }
        return calculatedItemsSubtotal
    }

    public mutating func updateItemQuantity(id: UUID, quantity: Int) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx].updateQuantity(quantity)
        }
    }

    public mutating func updateItemPrice(id: UUID, price: Double) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx].updatePrice(price)
        }
    }

    /// Calculates user's share based on selected items and optional custom quantities.
    /// Tax/service/discount are distributed proportionally based on selected items' proportion of the effective subtotal.
    public func calculateShare(
        selectedItemIds: Set<UUID>,
        customQuantities: [UUID: Int] = [:]
    ) -> Double {
        breakdown(for: selectedItemIds, customQuantities: customQuantities).totalShare
    }

    /// Breakdown helper for UI display with support for adjusted quantities per item
    public func breakdown(
        for selectedItemIds: Set<UUID>,
        customQuantities: [UUID: Int] = [:]
    ) -> (
        selectedSubtotal: Double,
        proportionalTax: Double,
        proportionalService: Double,
        proportionalDiscount: Double,
        totalShare: Double
    ) {
        let selectedItems = items.filter { selectedItemIds.contains($0.id) }
        let selectedSubtotal = selectedItems.reduce(0) { sum, item in
            let qty = customQuantities[item.id] ?? item.quantity
            return sum + (item.price * Double(max(0, qty)))
        }

        guard selectedSubtotal > 0 else {
            return (0, 0, 0, 0, 0)
        }

        let baseSubtotal = effectiveSubtotal
        let ratio = baseSubtotal > 0 ? min(max(selectedSubtotal / baseSubtotal, 0.0), 1.0) : 0.0
        let proportionalTax = tax * ratio
        let proportionalService = serviceCharge * ratio
        let proportionalDiscount = discount * ratio
        let totalShare = max(0, selectedSubtotal + proportionalTax + proportionalService - proportionalDiscount)

        return (selectedSubtotal, proportionalTax, proportionalService, proportionalDiscount, totalShare)
    }

    /// Generates a summary note for the selected/adjusted items (e.g. "Split: Burger (2x), Ice Tea")
    public func summaryNote(
        for selectedItemIds: Set<UUID>,
        customQuantities: [UUID: Int] = [:]
    ) -> String {
        let names = items
            .filter { selectedItemIds.contains($0.id) }
            .map { item in
                let qty = customQuantities[item.id] ?? item.quantity
                return qty > 1 ? "\(item.name) (\(qty)x)" : item.name
            }
        guard !names.isEmpty else { return "Split bill" }
        return "Split: " + names.joined(separator: ", ")
    }
}
