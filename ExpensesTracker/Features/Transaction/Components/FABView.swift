//
//  FABView.swift
//  ExpensesTracker
//
//  Created by Fidel Fausta Cavell on 01/09/26.
//

import SwiftUI

struct FABView: View {
    @Environment(Router.self) private var router
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Menu {
                    Button {
                        router.navigate(to: .cameraFastVLM)
                    } label: {
                        Label("Scan Receipt", systemImage: Icon.scanReceipt)
                    }
                    
                    Button {
                        router.navigate(to: .voiceTranscription)
                    } label: {
                        Label("Voice Input", systemImage: Icon.microphone)
                    }
                    
                    Button {
                        router.navigate(to: .newTransaction)
                    } label: {
                        Label("Add Manually", systemImage: Icon.addManually)
                    }
                } label: {
                    Image(systemName: Icon.plus)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.glass)
                .clipShape(.circle)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.trailing, 18)
                .padding(.bottom, 24)
            }
        }
    }
}

#Preview {
    FABView()
        .environment(Router())
}
