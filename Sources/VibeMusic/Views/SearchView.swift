import SwiftUI

struct SearchView: View {
    @EnvironmentObject var player: PlayerService
    @EnvironmentObject var library: LibraryService
    @State private var query = ""
    @State private var results: [Track] = []
    @State private var isSearching = false
    @State private var source: SearchSource = .youtube
    @State private var error: String?
    @FocusState private var focused: Bool

    enum SearchSource: String, CaseIterable {
        case youtube = "YouTube"; case soundcloud = "SoundCloud"; case all = "All"
        var icon: String {
            switch self {
            case .youtube:    return "play.rectangle.fill"
            case .soundcloud: return "cloud.fill"
            case .all:        return "magnifyingglass"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 14) {
                HStack {
                    Text("Search").font(.system(size: 28, weight: .black)).foregroundStyle(Color.vText)
                    Spacer()
                }.padding(.horizontal, 20).padding(.top, 60)

                // Search field
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(focused ? Color.vGreen : Color.vSubtext)
                        .font(.system(size: 17))
                    TextField("Songs, artists, albums…", text: $query)
                        .foregroundStyle(Color.vText).tint(Color.vGreen)
                        .focused($focused).submitLabel(.search)
                        .onSubmit { Task { await search() } }
                    if !query.isEmpty {
                        Button { query = ""; results = []; error = nil } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(Color.vHint)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 13)
                .background(Color.vSurface)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(focused ? Color.vGreen.opacity(0.5) : Color.vStroke, lineWidth: 1))
                .padding(.horizontal, 20)

                // Source picker
                HStack(spacing: 8) {
                    ForEach(SearchSource.allCases, id: \.self) { s in
                        Button {
                            source = s
                            if !query.isEmpty { Task { await search() } }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: s.icon).font(.system(size: 11, weight: .bold))
                                Text(s.rawValue).font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(source == s ? Color.vBG : Color.vSubtext)
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(source == s ? Color.vGreen : Color.vSurface)
                            .clipShape(Capsule())
                            .shadow(color: source == s ? Color.vGreen.opacity(0.4) : .clear, radius: 8)
                        }
                    }
                    Spacer()
                }.padding(.horizontal, 20)
            }
            .background(Color.vBG)
            .padding(.bottom, 8)

            // Content
            if isSearching {
                Spacer()
                VStack(spacing: 14) {
                    SearchingAnimation()
                    Text("Searching…").font(.system(size: 15)).foregroundStyle(Color.vSubtext)
                }
                Spacer()
            } else if let err = error {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle").font(.system(size: 40)).foregroundStyle(Color.vSubtext)
                    Text(err).font(.system(size: 14)).foregroundStyle(Color.vSubtext).multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
                Spacer()
            } else if results.isEmpty && !query.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass").font(.system(size: 40)).foregroundStyle(Color.vHint)
                    Text("No results for \"\(query)\"").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.vSubtext)
                    Text("Try a different source or spelling").font(.system(size: 13)).foregroundStyle(Color.vHint)
                }
                Spacer()
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(results) { track in
                            TrackRow(track: track)
                                .onTapGesture {
                                    player.play(track: track, queue: results)
                                    library.addRecent(track)
                                    player.showPlayer = true
                                }
                                .padding(.horizontal, 20)
                            Divider().background(Color.vStroke).padding(.leading, 82)
                        }
                        Spacer(minLength: 150)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .background(Color.vBG.ignoresSafeArea())
        .onChange(of: query) { q in
            if q.count >= 2 {
                Task { try? await Task.sleep(nanoseconds: 500_000_000); await search() }
            }
        }
    }

    private func search() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSearching = true; error = nil; results = []

        var yt: [Track] = []
        var sc: [Track] = []

        switch source {
        case .youtube:
            yt = await YouTubeService.shared.search(query: query)
        case .soundcloud:
            sc = await SoundCloudService.shared.search(query: query)
        case .all:
            async let ytTask = YouTubeService.shared.search(query: query)
            async let scTask = SoundCloudService.shared.search(query: query)
            yt = await ytTask; sc = await scTask
        }

        var combined: [Track] = []
        // Interleave results
        let max = max(yt.count, sc.count)
        for i in 0..<max {
            if i < yt.count { combined.append(yt[i]) }
            if i < sc.count { combined.append(sc[i]) }
        }

        results = combined
        if results.isEmpty { error = "Could not reach \(source.rawValue). Check your connection." }
        isSearching = false
    }
}

struct SearchingAnimation: View {
    @State private var scale = false
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<5) { i in
                Capsule().fill(Color.vGreen)
                    .frame(width: 4, height: scale ? CGFloat.random(in: 12...30) : 8)
                    .animation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true).delay(Double(i)*0.08), value: scale)
            }
        }
        .greenGlow()
        .onAppear { scale = true }
    }
}
