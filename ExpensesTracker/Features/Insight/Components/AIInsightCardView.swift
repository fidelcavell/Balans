//
//  AIInsightCardView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 02/09/26.
//

import SwiftUI

struct AIInsightCardView: View {
    let report: InsightReport?
    let isLoading: Bool
    let isUnavailable: Bool
    let onRefresh: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AI Insights", systemImage: Icon.sparkles)
                    .font(.headline)
                
                Spacer()
                
                if !isLoading && !isUnavailable {
                    Button(action: onRefresh) {
                        Image(systemName: Icon.arrowClockwise)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 4)
            
            Group {
                if isUnavailable {
                    UnavailableView()
                } else if isLoading {
                    LoadingView()
                } else if let report {
                    ReportView(report: report)
                } else {
                    EmptyStateView(onGenerate: onRefresh)
                }
            }
        }
    }
}

private struct ReportView: View {
    let report: InsightReport
    
    var body: some View {
        VStack(spacing: 0) {
            InsightRow(
                icon: report.spendingOutlook == "Healthy" ? Icon.goodBalance : Icon.badBalance,
                iconColor: outlookColor(report.spendingOutlook),
                title: report.spendingOutlook,
                titleColor: outlookColor(report.spendingOutlook),
                content: report.summary
            )
            
            Divider().padding(.horizontal)
            
            InsightRow(
                icon: Icon.eye,
                iconColor: .blue,
                title: "Key Observation",
                titleColor: .secondary,
                content: report.topObservation
            )
            
            Divider().padding(.horizontal)
            
            InsightRow(
                icon: Icon.lightBulb,
                iconColor: .orange,
                title: "Saving Tips",
                titleColor: .secondary,
                content: report.savingsTip
            )
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct InsightRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let titleColor: Color
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.footnote.bold())
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(iconColor, in: Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(titleColor)
                
                Text(content)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }
}

private struct LoadingView: View {
    var body: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(.accentColor)
            Text("Generating insights…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct EmptyStateView: View {
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: Icon.sparkles)
                .font(.title)
                .foregroundStyle(.tertiary)
            
            Text("Tap below to generate AI-powered insights for this month.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onGenerate) {
                Label("Generate Insights", systemImage: "sparkles")
                    .font(.subheadline.bold())
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct UnavailableView: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: Icon.exclamationmarkTriangle)
                .foregroundStyle(.orange)
            Text("AI Insights require Apple Intelligence on this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Internal Helpers
private func outlookColor(_ outlook: String) -> Color {
    switch outlook {
    case "Healthy":  return .green
    case "Moderate": return .orange
    default:         return .red
    }
}

// MARK: - Preview
#Preview {
    let sampleReport = InsightReport(
        summary: "You spent 62% of your income this month, mostly on Food & Drinks and Transport.",
        topObservation: "Food & Drinks alone made up 38% of your total expenses — your highest category by far.",
        savingsTip: "Try capping Food & Drinks at 30% of expenses to free up more savings each month.",
        spendingOutlook: "Moderate"
    )
    
    ScrollView {
        VStack(spacing: 24) {
            // Populated report
            AIInsightCardView(
                report: sampleReport,
                isLoading: false,
                isUnavailable: false,
                onRefresh: {}
            )
            
            // Loading state
            AIInsightCardView(
                report: nil,
                isLoading: true,
                isUnavailable: false,
                onRefresh: {}
            )
            
            // Unavailable state
            AIInsightCardView(
                report: nil,
                isLoading: false,
                isUnavailable: true,
                onRefresh: {}
            )
            
            // Empty / pre-generate state
            AIInsightCardView(
                report: nil,
                isLoading: false,
                isUnavailable: false,
                onRefresh: {}
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}


