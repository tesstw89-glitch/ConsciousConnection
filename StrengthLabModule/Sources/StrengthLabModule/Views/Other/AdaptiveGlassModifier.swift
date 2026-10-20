//
//  AdaptiveGlassModifier.swift
//  SetDeck
//
//  Compatibility version for Xcode 16 / iOS 18 SDK
//

import SwiftUI

struct AdaptiveGlassModifier: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        content
            .background(tint)
            .cornerRadius(20)
    }
}
