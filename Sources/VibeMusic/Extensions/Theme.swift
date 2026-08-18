import SwiftUI

// MARK: - Color Palette
extension Color {
    static let vGreen      = Color(red: 0.18, green: 0.92, blue: 0.44)
    static let vGreenDark  = Color(red: 0.08, green: 0.60, blue: 0.28)
    static let vBG         = Color(red: 0.04, green: 0.05, blue: 0.04)
    static let vSurface    = Color(red: 0.09, green: 0.11, blue: 0.09)
    static let vGlass      = Color.white.opacity(0.07)
    static let vStroke     = Color.white.opacity(0.10)
    static let vText       = Color.white
    static let vSubtext    = Color.white.opacity(0.55)
    static let vHint       = Color.white.opacity(0.28)
}

// MARK: - Glass Card
struct GlassCard: ViewModifier {
    var radius: CGFloat = 18
    var padding: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: radius).fill(Color.vGlass)
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(
                            LinearGradient(colors: [Color.vStroke, Color.vGreen.opacity(0.06), Color.vStroke.opacity(0.4)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                }
            )
    }
}

extension View {
    func glassCard(radius: CGFloat = 18, padding: CGFloat = 0) -> some View {
        modifier(GlassCard(radius: radius, padding: padding))
    }

    func greenGlow(radius: CGFloat = 10) -> some View {
        self
            .shadow(color: Color.vGreen.opacity(0.5), radius: radius / 2)
            .shadow(color: Color.vGreen.opacity(0.25), radius: radius)
    }
}

// MARK: - Animated Waveform
struct WaveformBars: View {
    var isAnimating: Bool = true
    var barCount: Int = 4
    @State private var phase: Bool = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { i in
                Capsule()
                    .fill(Color.vGreen)
                    .frame(width: 3, height: barHeight(i))
                    .animation(
                        .easeInOut(duration: 0.38).repeatForever(autoreverses: true).delay(Double(i) * 0.1),
                        value: phase
                    )
            }
        }
        .onAppear { if isAnimating { phase.toggle() } }
        .onChange(of: isAnimating) { v in if v { phase.toggle() } }
    }

    private func barHeight(_ i: Int) -> CGFloat {
        guard isAnimating else { return 6 }
        let bases: [CGFloat] = [8, 18, 12, 22, 10, 20, 14]
        let alts:  [CGFloat] = [18, 8, 22, 10, 20, 12, 6]
        let arr = phase ? alts : bases
        return arr[i % arr.count]
    }
}
