//
//  InsightReport.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 02/09/26.
//

import Foundation
import FoundationModels

@Generable
struct InsightReport {
    @Guide(description: "A 1–2 sentence plain-language summary of the user's spending this month, e.g. 'You spent 45% of your income this month, mostly on Food & Drinks.'")
    var summary: String

    @Guide(description: "The single most notable observation about spending behaviour, e.g. 'Your Transport spending doubled compared to your typical category share.'")
    var topObservation: String

    @Guide(description: "One concrete, actionable saving tip tailored to the user's data, e.g. 'Try capping Food & Drinks at 30% of expenses to recover more savings.'")
    var savingsTip: String

    @Guide(description: "A short financial health verdict: either 'Healthy', 'Moderate', or 'At Risk', based on the savings rate and spending pattern.")
    var spendingOutlook: String
}
