import SwiftUI

struct RootView: View {
    @EnvironmentObject var player: PlayerService
    @EnvironmentObject var library: LibraryService
    @State private var tab: Tab = .home

    enum Tab: String, CaseIterable {
        case home    = "house.fill"
        case search  = "magnifyingglass"
        case library = "music.note.list"
        case settings = "gearshape.fill"

        var label: String {
            switch self {
            case .home:     return "Home"
            case .search:   return "Search"
            case .library:  return "Library"
            case .settings: return "Settings"
            }
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.vBG.ignoresSafeArea()

            // Pages
            Group {
                switch tab {
                case .home:     HomeView()
                case .search:   SearchView()
                case .library:  LibraryView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Mini player + tab bar
            VStack(spacing: 0) {
                if player.currentTrack != nil {
                    MiniPlayerView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.35), value: player.isPlaying)
                }
                TabBar(selected: $tab)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .fullScreenCover(isPresented: $player.showPlayer) {
            FullPlayerView()
                .environmentObject(library)
        }
    }
}

struct TabBar: View {
    @Binding var selected: RootView.Tab

    var body: some View {
        HStack {
            ForEach(RootView.Tab.allCases, id: \.self) { tab in
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selected = tab }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.rawValue)
                            .font(.system(size: 21, weight: selected == tab ? .bold : .regular))
                            .foregroundStyle(selected == tab ? Color.vGreen : Color.vHint)
                            .scaleEffect(selected == tab ? 1.1 : 1.0)
                            .greenGlow(radius: selected == tab ? 8 : 0)
                        Text(tab.label)
                            .font(.system(size: 10, weight: selected == tab ? .semibold : .regular))
                            .foregroundStyle(selected == tab ? Color.vGreen : Color.vHint)
                    }
                }
                Spacer()
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 28)
        .background(.ultraThinMaterial)
        .overlay(Rectangle().frame(height: 0.5).foregroundStyle(Color.vStroke), alignment: .top)
    }
}
