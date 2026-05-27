import SwiftUI

struct HomeView: View {
    @EnvironmentObject var playerService: AudioPlayerService
    @EnvironmentObject var libraryService: LibraryService
    @EnvironmentObject var authService: GoogleAuthService
    @State private var greeting = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(greeting)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(VibeColors.textSecondary)
                        Text(authService.userProfile?.name.components(separatedBy: " ").first ?? "Vibe")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(VibeColors.textPrimary)
                    }
                    Spacer()
                    VibeLogoMark()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)

                // Now Playing Card
                if let track = playerService.currentTrack {
                    NowPlayingCard(track: track)
                        .padding(.horizontal, 20)
                }

                // Recently Played
                if !libraryService.recentlyPlayed.isEmpty {
                    SectionHeader(title: "Recently Played", icon: "clock.fill")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(libraryService.recentlyPlayed.prefix(10)) { track in
                                TrackCard(track: track)
                                    .onTapGesture {
                                        playerService.play(track: track, queue: libraryService.recentlyPlayed)
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // Liked Tracks
                if !libraryService.likedTracks.isEmpty {
                    SectionHeader(title: "Liked Songs", icon: "heart.fill")
                    VStack(spacing: 8) {
                        ForEach(libraryService.likedTracks.prefix(5)) { track in
                            TrackRow(track: track)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Playlists
                if !libraryService.playlists.isEmpty {
                    SectionHeader(title: "Your Playlists", icon: "music.note.list")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(libraryService.playlists) { playlist in
                                PlaylistCard(playlist: playlist)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                // Spacer for tab bar + mini player
                Spacer(minLength: 160)
            }
        }
        .background(VibeColors.background.ignoresSafeArea())
        .onAppear { updateGreeting() }
    }

    private func updateGreeting() {
        let h = Calendar.current.component(.hour, from: Date())
        greeting = h < 12 ? "Good Morning ☀️" : h < 17 ? "Good Afternoon 🌤" : "Good Evening 🌙"
    }
}

struct VibeLogoMark: View {
    @State private var rotate = false
    var body: some View {
        ZStack {
            Circle()
                .fill(VibeColors.primary.opacity(0.15))
                .frame(width: 44, height: 44)
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(VibeColors.primary)
                .glowEffect()
                .rotationEffect(.degrees(rotate ? 360 : 0))
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { rotate = true }
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(VibeColors.primary)
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(VibeColors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 20)
    }
}

struct NowPlayingCard: View {
    let track: Track
    @EnvironmentObject var playerService: AudioPlayerService
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: track.thumbnailURL ?? "")) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(VibeColors.surface)
                    .overlay(Image(systemName: "music.note").foregroundStyle(VibeColors.primary))
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: VibeColors.primary.opacity(pulse ? 0.4 : 0.1), radius: pulse ? 16 : 8)

            VStack(alignment: .leading, spacing: 3) {
                Text("Now Playing")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(VibeColors.primary)
                Text(track.title).lineLimit(1)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(VibeColors.textPrimary)
                Text(track.artist).lineLimit(1)
                    .font(.system(size: 13))
                    .foregroundStyle(VibeColors.textSecondary)
            }
            Spacer()
            Button(action: { playerService.playPause() }) {
                Image(systemName: playerService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(VibeColors.primary)
                    .glowEffect()
            }
        }
        .padding(16)
        .liquidGlass(cornerRadius: 18)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { pulse = true }
        }
    }
}

struct TrackCard: View {
    let track: Track
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: track.thumbnailURL ?? "")) { img in
                img.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(VibeColors.surface)
                    .overlay(Image(systemName: "music.note").foregroundStyle(VibeColors.primary))
            }
            .frame(width: 130, height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text(track.title).lineLimit(1)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(VibeColors.textPrimary)
            Text(track.artist).lineLimit(1)
                .font(.system(size: 11))
                .foregroundStyle(VibeColors.textSecondary)
        }
        .frame(width: 130)
    }
}

struct PlaylistCard: View {
    let playlist: Playlist
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(VibeColors.surface)
                    .frame(width: 130, height: 130)
                if playlist.tracks.isEmpty {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 36))
                        .foregroundStyle(VibeColors.primary.opacity(0.6))
                } else {
                    LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 2), count: 2), spacing: 2) {
                        ForEach(playlist.tracks.prefix(4)) { track in
                            AsyncImage(url: URL(string: track.thumbnailURL ?? "")) { img in
                                img.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: { VibeColors.surface }
                                .frame(width: 63, height: 63)
                                .clipped()
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            Text(playlist.name).lineLimit(1)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(VibeColors.textPrimary)
            Text("\(playlist.trackCount) songs")
                .font(.system(size: 11))
                .foregroundStyle(VibeColors.textSecondary)
        }
        .frame(width: 130)
    }
}
