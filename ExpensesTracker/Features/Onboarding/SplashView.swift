//
//  SplashView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 31/05/26.
//

import SwiftUI
import SwiftData

struct SplashView: View {
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    
    @State private var hasViewLoaded: Bool = false
    
    @State private var scale: Double = 0.6
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            if hasViewLoaded {
                if hasOnboarded {
                    AppTabView()
                        .background(Color(.systemGroupedBackground).ignoresSafeArea())
                } else {
                    CreatePreferenceView()
                }
            } else {
                Image("img_icon")
                    .resizable()
                    .frame(width: 120, height: 100)
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
        }
        .onAppear {
            // Logo's Animation
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.1
                opacity = 1
            }
            
            // Bounce Effect
            withAnimation(.spring(
                response: 0.5,
                dampingFraction: 0.6
            ).delay(0.8)) {
                scale = 1.0
                hasViewLoaded = true
            }
        }
        .task {
            // Eagerly preload FastVLM so it's ready when the camera is used
            do {
                try await FastVLMManager.shared.loadModel()
            } catch {
                print("[FastVLM] Preload failed: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    SplashView()
}
