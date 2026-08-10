//
//  BalansWidget.swift
//  BalansWidget
//
//  Created by Fidel Fausta Cavell on 06/08/26.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct BalansEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData
}

// MARK: - Timeline Provider
struct BalansProvider: TimelineProvider {
    func placeholder(in context: Context) -> BalansEntry {
        BalansEntry(date: .now, widgetData: .placeholder)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (BalansEntry) -> Void) {
        let data = context.isPreview ? .placeholder : loadWidgetData()
        completion(BalansEntry(date: .now, widgetData: data))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<BalansEntry>) -> Void) {
        let data = loadWidgetData()
        let entry = BalansEntry(date: .now, widgetData: data)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry View (size-aware)
struct BalansWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: BalansEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.widgetData)
        default:
            MediumWidgetView(data: entry.widgetData)
        }
    }
}

// MARK: - Widget Configuration
struct BalansWidget: Widget {
    let kind: String = "BalansWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BalansProvider()) { entry in
            if #available(iOS 17.0, *) {
                BalansWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                BalansWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Balans")
        .description("See your monthly income, expenses, and balance at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews
#Preview("Small", as: .systemSmall) {
    BalansWidget()
} timeline: {
    BalansEntry(date: .now, widgetData: .placeholder)
}

#Preview("Medium", as: .systemMedium) {
    BalansWidget()
} timeline: {
    BalansEntry(date: .now, widgetData: .placeholder)
}

#Preview("Medium - Over Limit", as: .systemMedium) {
    BalansWidget()
} timeline: {
    BalansEntry(
        date: .now,
        widgetData: WidgetData(
            totalIncome: 3_000_000,
            totalExpense: 4_500_000,
            monthlySpendingLimit: 4_000_000,
            monthName: "August",
            lastUpdated: .now
        )
    )
}
