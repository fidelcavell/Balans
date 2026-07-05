//
//  LottieAnimationView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 09/06/26.
//

import SwiftUI
import DotLottie

struct LottieAnimationView: View {
    let fileName: String

        var body: some View {
            if let url = Bundle.main.url(
                forResource: fileName,
                withExtension: "lottie"
            ),
            let data = try? Data(contentsOf: url) {

                DotLottieView(
                    dotLottie: DotLottieAnimation(
                        lottieData: data,
                        config: AnimationConfig(
                            autoplay: true,
                            loop: true
                        )
                    )
                )
            }
        }
}

#Preview {
    LottieAnimationView(
        fileName: "around_globe"
    )
}
