// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Combine

// MARK: - TypewriterText Animation
struct TypewriterText: View {
    let text: String
    @Binding var isAnimating: Bool
    @State private var displayedText = ""
    @State private var currentIndex = 0
    @State private var characterDelay = 0.02
    
    var body: some View {
        Text(displayedText)
            .font(.body)
            .opacity(0.9)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .onAppear {
                if isAnimating && currentIndex == 0 {
                    animateText()
                }
            }
            .onChange(of: isAnimating) { newValue in
                if newValue && currentIndex == 0 {
                    animateText()
                }
            }
    }
    
    private func animateText() {
        guard currentIndex < text.count else {
            isAnimating = false
            return
        }
        
        let index = text.index(text.startIndex, offsetBy: currentIndex)
        displayedText.append(text[index])
        currentIndex += 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + characterDelay) {
            animateText()
        }
    }
}
