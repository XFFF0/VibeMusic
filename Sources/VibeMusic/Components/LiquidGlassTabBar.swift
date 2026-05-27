import SwiftUI

struct LiquidGlassTabBar: View {
    @Binding var selectedTab: ContentView.Tab
    @State private var animateTab: ContentView.Tab? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ContentView.Tab.allCases, id: \.self) { tab in
                TabBarItem(tab: tab, isSelected: selectedTab == tab, animate: animateTab == tab) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selectedTab = tab
                        animateTab = tab
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { animateTab = nil }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .padding(.bottom, 6)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 28)
                    .fill(VibeColors.glass)
                RoundedRectangle(cornerRadius: 28)
                    .stroke(
                        LinearGradient(
                            colors: [VibeColors.primary.opacity(0.25), VibeColors.glassStroke, VibeColors.glassStroke],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: VibeColors.primary.opacity(0.08), radius: 24)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

struct TabBarItem: View {
    let tab: ContentView.Tab
    let isSelected: Bool
    let animate: Bool
    let action: () -> Void

    var label: String {
        switch tab {
        case .home: return "Home"
        case .search: return "Search"
        case .library: return "Library"
        case .profile: return "Profile"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(VibeColors.primary.opacity(0.18))
                            .frame(width: 44, height: 32)
                            .glowEffect(radius: 6)
                    }
                    Image(systemName: tab.rawValue)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? VibeColors.primary : VibeColors.textSecondary)
                        .scaleEffect(animate ? 1.25 : 1.0)
                }
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? VibeColors.primary : VibeColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
