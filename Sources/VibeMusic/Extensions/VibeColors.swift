import SwiftUI

enum VibeColors {
    static let background    = Color(red: 0.04, green: 0.06, blue: 0.04)
    static let surface       = Color(red: 0.08, green: 0.12, blue: 0.08)
    static let primary       = Color(red: 0.18, green: 0.92, blue: 0.44)   // Electric green
    static let primaryGlow   = Color(red: 0.10, green: 0.75, blue: 0.30)
    static let secondary     = Color(red: 0.05, green: 0.55, blue: 0.25)
    static let accent        = Color(red: 0.40, green: 1.00, blue: 0.60)
    static let glass         = Color.white.opacity(0.06)
    static let glassStroke   = Color.white.opacity(0.12)
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let textTertiary  = Color.white.opacity(0.30)

    static let gradientMain = LinearGradient(
        colors: [primary.opacity(0.8), primaryGlow.opacity(0.4), Color.clear],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let gradientGlow = RadialGradient(
        colors: [primary.opacity(0.25), Color.clear],
        center: .center,
        startRadius: 0,
        endRadius: 200
    )
}

// MARK: - Liquid Glass Effect
struct LiquidGlassBackground: ViewModifier {
    var intensity: Double = 1.0
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(VibeColors.glass)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    VibeColors.glassStroke.opacity(intensity),
                                    VibeColors.primary.opacity(0.08 * intensity),
                                    VibeColors.glassStroke.opacity(intensity * 0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: VibeColors.primary.opacity(0.08 * intensity), radius: 20)
            )
    }
}

extension View {
    func liquidGlass(intensity: Double = 1.0, cornerRadius: CGFloat = 20) -> some View {
        modifier(LiquidGlassBackground(intensity: intensity, cornerRadius: cornerRadius))
    }
}

// MARK: - Glow Effect
struct GlowModifier: ViewModifier {
    var color: Color = VibeColors.primary
    var radius: CGFloat = 12
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
            .shadow(color: color.opacity(0.15), radius: radius * 2)
    }
}

extension View {
    func glowEffect(color: Color = VibeColors.primary, radius: CGFloat = 12) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}
