import SwiftUI

@MainActor
struct CloudsTheme {
    var background: Color
    var topLeading: Color
    var topTrailing: Color
    var bottomLeading: Color
    var bottomTrailing: Color

    static func dynamicTheme(for accent: AccentColor, scheme: ColorScheme) -> CloudsTheme {
        let (r, g, b) = accent.rgbComponents

        if scheme == .dark {
            let bgR = r * 0.12
            let bgG = g * 0.08
            let bgB = b * 0.15

            return CloudsTheme(
                background: Color(
                    red: max(0.05, bgR),
                    green: max(0.03, bgG),
                    blue: max(0.10, bgB)
                ),
                topLeading: Color(red: r * 0.85, green: g * 0.65, blue: b * 0.95).opacity(0.75),
                topTrailing: Color(red: r * 0.6, green: g * 0.75, blue: b * 0.85).opacity(0.60),
                bottomLeading: Color(red: r * 0.7, green: g * 0.5, blue: b * 0.85).opacity(0.55),
                bottomTrailing: Color(red: r * 0.9, green: g * 0.5, blue: b * 0.7).opacity(0.65)
            )
        } else {
            let bgR = 0.94 + r * 0.04
            let bgG = 0.92 + g * 0.04
            let bgB = 0.96 + b * 0.03

            return CloudsTheme(
                background: Color(
                    red: min(0.98, bgR),
                    green: min(0.97, bgG),
                    blue: min(0.99, bgB)
                ),
                topLeading: Color(red: r * 0.85, green: g * 0.7, blue: b * 0.9).opacity(0.55),
                topTrailing: Color(red: r * 0.7, green: g * 0.8, blue: b * 0.85).opacity(0.45),
                bottomLeading: Color(red: r * 0.75, green: g * 0.65, blue: b * 0.85).opacity(0.40),
                bottomTrailing: Color(red: r * 0.9, green: g * 0.7, blue: b * 0.8).opacity(0.50)
            )
        }
    }
}

@MainActor
final class CloudProvider: ObservableObject {
    let offset: CGSize
    let frameHeightRatio: CGFloat

    init() {
        frameHeightRatio = CGFloat.random(in: 0.7..<1.4)
        offset = CGSize(
            width: CGFloat.random(in: -150..<150),
            height: CGFloat.random(in: -150..<150)
        )
    }
}

struct Cloud: View {
    @StateObject private var provider = CloudProvider()

    let proxy: GeometryProxy
    let color: Color
    let rotationStart: Double
    let duration: Double
    let alignment: Alignment

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let progress = (t.truncatingRemainder(dividingBy: duration)) / duration
            let angle = rotationStart + progress * 360

            Circle()
                .fill(color)
                .frame(height: proxy.size.height / provider.frameHeightRatio)
                .offset(provider.offset)
                .rotationEffect(.degrees(angle))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
                .opacity(0.8)
        }
    }
}

@MainActor
struct FloatingClouds: View {
    @Environment(\.colorScheme) private var scheme
    @ObservedObject private var themeManager = ThemeManager.shared

    var customTheme: CloudsTheme?
    let blur: CGFloat

    init(theme: CloudsTheme? = nil, blur: CGFloat = 60) {
        self.customTheme = theme
        self.blur = blur
    }

    private var currentTheme: CloudsTheme {
        if let customTheme {
            return customTheme
        }
        return CloudsTheme.dynamicTheme(for: themeManager.accentColor, scheme: scheme)
    }

    var body: some View {
        let t = currentTheme

        GeometryReader { proxy in
            ZStack {
                t.background

                Cloud(
                    proxy: proxy,
                    color: t.bottomTrailing,
                    rotationStart: 0,
                    duration: 60,
                    alignment: .bottomTrailing
                )

                Cloud(
                    proxy: proxy,
                    color: t.topTrailing,
                    rotationStart: 240,
                    duration: 50,
                    alignment: .topTrailing
                )

                Cloud(
                    proxy: proxy,
                    color: t.bottomLeading,
                    rotationStart: 120,
                    duration: 80,
                    alignment: .bottomLeading
                )

                Cloud(
                    proxy: proxy,
                    color: t.topLeading,
                    rotationStart: 180,
                    duration: 70,
                    alignment: .topLeading
                )
            }
            .blur(radius: blur)
            .ignoresSafeArea()
        }
    }
}


