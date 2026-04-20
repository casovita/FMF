import SwiftUI

struct AtmosphericBackground: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: [
                        Color(hex: 0x0D1628),
                        Color(hex: 0x121A2E),
                        Color(hex: 0x0F1923),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Top-left radial blue glow
                let glowSize = geo.size.width * 0.95
                RadialGradient(
                    colors: [
                        FMFColors.brandAccent.opacity(0.18),
                        .clear,
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: glowSize / 2
                )
                .frame(width: glowSize, height: glowSize)
                .offset(x: -geo.size.width * 0.5 + glowSize / 2 - 80, y: -geo.size.height * 0.5 + glowSize / 2 - 120)

                // Vertical light strip
                LinearGradient(
                    colors: [.clear, .white.opacity(0.025), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 120, height: geo.size.height * 0.5)
                .offset(
                    x: geo.size.width * 0.28 - geo.size.width / 2 + 60,
                    y: geo.size.height * 0.3 - geo.size.height / 2 + geo.size.height * 0.25
                )
            }
        }
        .ignoresSafeArea()
    }
}
