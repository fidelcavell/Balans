//
//  OnboardingView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 31/05/26.
//

import SwiftUI

struct OnboardingItemData {
    let assetName: String
    let headline: String
    let description: String
}

struct OnboardingView: View {
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    @State private var currentPage: Int = 0
    @State private var navigateToNext: Bool = false
    
    var onboardingData = [
        OnboardingItemData(
            assetName: "around_globe",
            headline: "Keep organize",
            description: "Access vocabulary anytime, anywhere. Build your skills on the go without limits."
        ),
        OnboardingItemData(
            assetName: "identify_report",
            headline: "Detail report",
            description: "Access vocabulary anytime, anywhere. Build your skills on the go without limits."
        ),
    ]
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Onboarding Content:
                TabView(selection: $currentPage) {
                    ForEach(0..<onboardingData.count, id: \.self) { index in
                        OnboardingItem(
                            assetName: onboardingData[index].assetName,
                            headline: onboardingData[index].headline,
                            description: onboardingData[index].description,
                            isLast: index == onboardingData.count - 1,
                            action: {
                                if index == onboardingData.count - 1 {
                                    hasOnboarded = true
                                } else {
                                    withAnimation {
                                        currentPage += 1
                                    }
                                }
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<onboardingData.count, id: \.self) { index in
                        Capsule()
                            .fill(
                                currentPage == index
                                ? Color.primaryBrand
                                : Color.gray.opacity(0.3)
                            )
                            .frame(
                                width: currentPage == index ? 24 : 8,
                                height: 8
                            )
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 30)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
