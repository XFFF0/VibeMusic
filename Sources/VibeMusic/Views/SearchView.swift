import SwiftUI

struct SearchView: View {
    @StateObject private var searchService = MusicSearchService.shared
    @EnvironmentObject var playerService: AudioPlayerService
    @EnvironmentObject var libraryService: LibraryService
    @State private var query = ""
    @State private var selectedSources: Set<Track.Source> = [.youtubeMusic, .youtube, .spotify]
    @State private var selectedTrack: Track?
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            VStack(spacing: 14) {
                HStack {
                    Text("Search")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(VibeColors.textPrimary)
                    Spacer()
                }

                // Search field
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(searchFocused ? VibeColors.primary : VibeColors.textSecondary)
                        .font(.system(size: 17, weight: .medium))
                    TextField("Artists, songs, podcasts…", text: $query)
                        .foregroundStyle(VibeColors.textPrimary)
                        .tint(VibeColors.primary)
                        .focused($searchFocused)
                        .submitLabel(.search)
                        .onSubmit { performSearch() }
                    if !query.isEmpty {
                        Button(action: { query = ""; searchService.results = [] }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(VibeColors.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(VibeColors.glass)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(searchFocused ? VibeColors.primary.opacity(0.5) : VibeColors.glassStroke, lineWidth: 1)
                )

                // Source filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach([Track.Source.youtubeMusic, .youtube, .spotify], id: \.self) { source in
                            SourceChip(source: source, isSelected: selectedSources.contains(source)) {
                                if selectedSources.contains(source) {
                                    if selectedSources.count > 1 { selectedSources.remove(source) }
                                } else {
                                    selectedSources.insert(source)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 16)
            .background(VibeColors.background)

            // Results
            if searchService.isSearching {
                VStack {
                    Spacer()
                    VibeLoader()
                    Spacer()
                }
            } else if searchService.results.isEmpty && !query.isEmpty {
                EmptySearchView(query: query)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(searchService.results) { track in
                            TrackRow(track: track)
                                .onTapGesture {
                                    selectedTrack = track
                                    playerService.play(track: track, queue: searchService.results)
                                    libraryService.addToRecent(track)
                                }
                                .padding(.horizontal, 20)
                            Divider()
                                .background(VibeColors.glassStroke)
                                .padding(.leading, 86)
                        }
                        Spacer(minLength: 160)
                    }
                }
            }
        }
        .background(VibeColors.background.ignoresSafeArea())
        .sheet(item: $selectedTrack) { track in
            TrackDetailSheet(track: track)
        }
        .onChange(of: query) { newValue in
            if newValue.count >= 2 {
                Task { await searchService.search(query: newValue, sources: Array(selectedSources)) }
            }
        }
    }

    private func performSearch() {
        guard !query.isEmpty else { return }
        Task { await searchService.search(query: query, sources: Array(selectedSources)) }
    }
}

struct SourceChip: View {
    let source: Track.Source
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: sourceIcon)
                    .font(.system(size: 11, weight: .semibold))
                Text(source.displayName)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? VibeColors.background : VibeColors.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? VibeColors.primary : VibeColors.glass)
            .clipShape(Capsule())
            .shadow(color: isSelected ? VibeColors.primary.opacity(0.4) : .clear, radius: 8)
        }
    }

    var sourceIcon: String {
        switch source {
        case .youtubeMusic: return "music.note"
        case .youtube:      return "play.rectangle.fill"
        case .spotify:      return "circle.hexagonpath.fill"
        default: return "music.note"
        }
    }
}

struct EmptySearchView: View {
    let query: String
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(VibeColors.textTertiary)
            Text("No results for "\(query)"")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(VibeColors.textSecondary)
            Text("Try a different search")
                .font(.system(size: 14))
                .foregroundStyle(VibeColors.textTertiary)
            Spacer()
        }
    }
}

struct VibeLoader: View {
    @State private var animate = false
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<4) { i in
                Capsule()
                    .fill(VibeColors.primary)
                    .frame(width: 4, height: animate ? 28 : 10)
                    .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.12), value: animate)
            }
        }
        .glowEffect()
        .onAppear { animate = true }
    }
}
