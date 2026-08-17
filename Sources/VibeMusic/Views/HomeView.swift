import SwiftUI

struct HomeView: View {
    @EnvironmentObject var player: PlayerService
    @EnvironmentObject var library: LibraryService

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greeting())
                            .font(.system(size: 14)).foregroundStyle(Color.vSubtext)
                        Text("Vibe Music")
                            .font(.system(size: 30, weight: .black)).foregroundStyle(Color.vText)
                    }
                    Spacer()
                    ZStack {
                        Circle().fill(Color.vGreen.opacity(0.15)).frame(width: 46, height: 46)
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 30)).foregroundStyle(Color.vGreen).greenGlow()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                // Now Playing banner
                if let track = player.currentTrack {
                    NowPlayingBanner(track: track)
                        .padding(.horizontal, 20)
                }

                // Recent
                if !library.recent.isEmpty {
                    SectionView(title: "Recently Played", icon: "clock.fill") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(library.recent.prefix(10)) { track in
                                    TrackCard(track: track)
                                        .onTapGesture { player.play(track: track, queue: Array(library.recent.prefix(10))) }
                                }
                            }.padding(.horizontal, 20)
                        }
                    }
                }

                // Liked songs
                if !library.liked.isEmpty {
                    SectionView(title: "Liked Songs", icon: "heart.fill") {
                        VStack(spacing: 0) {
                            ForEach(library.liked.prefix(5)) { track in
                                TrackRow(track: track)
                                    .onTapGesture { player.play(track: track, queue: library.liked) }
                                    .padding(.horizontal, 20)
                                Divider().background(Color.vStroke).padding(.leading, 82)
                            }
                        }
                    }
                }

                // Playlists
                if !library.playlists.isEmpty {
                    SectionView(title: "Your Playlists", icon: "music.note.list") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(library.playlists) { pl in
                                    PlaylistCard(playlist: pl)
                                }
                            }.padding(.horizontal, 20)
                        }
                    }
                }

                // Empty state
                if library.recent.isEmpty && library.liked.isEmpty {
                    EmptyHomeView()
                }

                Spacer(minLength: 150)
            }
        }
        .background(Color.vBG.ignoresSafeArea())
    }

    private func greeting() -> String {
        let h = Calendar.current.component(.hour, from: Date())
        return h < 12 ? "Good Morning ☀️" : h < 17 ? "Good Afternoon 🌤" : "Good Evening 🌙"
    }
}

struct SectionView<Content: View>: View {
    let title: String; let icon: String; @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: icon).font(.system(size: 13, weight: .bold)).foregroundStyle(Color.vGreen)
                Text(title).font(.system(size: 19, weight: .bold)).foregroundStyle(Color.vText)
            }.padding(.horizontal, 20)
            content
        }
    }
}

struct NowPlayingBanner: View {
    let track: Track
    @EnvironmentObject var player: PlayerService

    var body: some View {
        HStack(spacing: 14) {
            ArtworkView(url: track.artworkURL, size: 54, radius: 10)
            VStack(alignment: .leading, spacing: 3) {
                Text("Now Playing").font(.system(size: 11, weight: .semibold)).foregroundStyle(Color.vGreen)
                Text(track.title).font(.system(size: 15, weight: .bold)).foregroundStyle(Color.vText).lineLimit(1)
                Text(track.artist).font(.system(size: 13)).foregroundStyle(Color.vSubtext).lineLimit(1)
            }
            Spacer()
            Button { player.playPause() } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 38)).foregroundStyle(Color.vGreen).greenGlow()
            }
        }
        .padding(14)
        .glassCard(radius: 16)
    }
}

struct TrackCard: View {
    let track: Track
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ArtworkView(url: track.artworkURL, size: 130, radius: 12)
            Text(track.title).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.vText).lineLimit(1)
            Text(track.artist).font(.system(size: 11)).foregroundStyle(Color.vSubtext).lineLimit(1)
        }.frame(width: 130)
    }
}

struct PlaylistCard: View {
    let playlist: Playlist
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(Color.vSurface).frame(width: 130, height: 130)
                if playlist.tracks.isEmpty {
                    Image(systemName: "music.note.list").font(.system(size: 36)).foregroundStyle(Color.vGreen.opacity(0.5))
                } else {
                    LazyVGrid(columns: [.init(.flexible(), spacing: 2), .init(.flexible(), spacing: 2)], spacing: 2) {
                        ForEach(playlist.tracks.prefix(4)) { t in
                            ArtworkView(url: t.artworkURL, size: 63, radius: 0)
                        }
                    }.clipShape(RoundedRectangle(cornerRadius: 12)).frame(width: 130, height: 130)
                }
            }
            Text(playlist.name).font(.system(size: 13, weight: .semibold)).foregroundStyle(Color.vText).lineLimit(1)
            Text("\(playlist.tracks.count) songs").font(.system(size: 11)).foregroundStyle(Color.vSubtext)
        }.frame(width: 130)
    }
}

struct EmptyHomeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform").font(.system(size: 52)).foregroundStyle(Color.vGreen.opacity(0.4))
            Text("Start listening").font(.system(size: 20, weight: .bold)).foregroundStyle(Color.vSubtext)
            Text("Search for songs to begin").font(.system(size: 14)).foregroundStyle(Color.vHint)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }
}
