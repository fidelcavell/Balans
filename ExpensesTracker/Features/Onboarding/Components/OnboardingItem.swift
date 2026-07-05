//
//  OnboardingItem.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 03/06/26.
//

import SwiftUI
import DotLottie

struct OnboardingItem: View {
    var assetName: String
    var headline: String
    var description: String
    
    var isLast: Bool
    var action: () -> Void
    
    var body: some View {
        VStack {
            LottieAnimationView(fileName: assetName)
                .frame(width: 250, height: 200)
            
            VStack(spacing: 12) {
                Text(headline)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(Color.secondaryBrand)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 42)
            
            Button(action: action) {
                Text(isLast ? "Get Started" : "Next")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.primaryBrand)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 42)
            .padding(.top, 24)
        }
    }
}

#Preview {
    OnboardingItem(
        assetName: "around_globe",
        headline: "Learn Anywhere",
        description: "Access vocabulary anytime, anywhere. Build your skills on the go without limits.",
        isLast: true,
        action: {
            print("Tapped!")
        }
    )
}
