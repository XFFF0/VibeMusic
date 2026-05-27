import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: GoogleAuthService
    @EnvironmentObject var playerService: AudioPlayerService
    @State private var selectedTab: Tab = .home

    enum Tab: String, CaseIterable {
        case home = "house.fill"
        case search = "magnifyingglass"
        case library = "music.note.list"
        case profile = "person.circle.fill"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)
                SearchView()
                    .tag(Tab.search)
                LibraryView()
                    .tag(Tab.library)
                ProfileView()
                    .tag(Tab.profile)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 0) {
                if playerService.currentTrack != nil {
                    MiniPlayerView()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                LiquidGlassTabBar(selectedTab: $selectedTab)
            }
        }
        .background(VibeColors.background.ignoresSafeArea())
        .ignoresSafeArea(edges: .bottom)
    }
}
