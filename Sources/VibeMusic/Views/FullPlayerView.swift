import SwiftUI

struct FullPlayerView: View {
    @EnvironmentObject var playerService: AudioPlayerService
    @EnvironmentObject var libraryService: LibraryService
    @Environment(\.dismiss) var dismiss
    @State private var showLyrics = false
    @State private var lyrics: String?
    @State private var isDraggingSlider = false

    var body: some View {
        ZStack {
            // Background gradient
            if let track = playerService.currentTrack {
                AsyncImage(url: URL(string: track.thumbnailURL ?? "")) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                        .blur(radius: 80).opacity(0.25).scaleEffect(1.5)
                } placeholder: { Color.clear }
                    .ignoresSafeArea()
            }
            VibeColors.background.opacity(0.85).ignoresSafeArea()

            // Ambient glow
            Circle()
                .fill(VibeColors.primary.opacity(playerService.isPlaying ? 0.12 : 0.06))
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(y: -80)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: playerService.isPlaying)

            VStack(spacing: 0) {
                // Drag handle
                Capsule().fill(VibeColors.glassStroke)
                    .frame(width: 40, height: 5)
                    .padding(.top, 14)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Artwork
                        Group {
                            if let track = playerService.currentTrack {
                                AsyncImage(url: URL(string: track.thumbnailURL ?? "")) { img in
                                    img.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 24).fill(VibeColors.surface)
                                        Image(systemName: "music.note").font(.system(size: 64)).foregroundStyle(VibeColors.primary.opacity(0.6))
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                                .shadow(color: VibeColors.primary.opacity(playerService.isPlaying ? 0.35 : 0.1), radius: playerService.isPlaying ? 40 : 20)
                                .scaleEffect(playerService.isPlaying ? 1.0 : 0.92)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: playerService.isPlaying)
                            }
                        }
                        .frame(width: 300, height: 300)
                        .padding(.top, 20)

                        // Track Info + Like
                        if let track = playerService.currentTrack {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(track.title)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundStyle(VibeColors.textPrimary)
                                        .lineLimit(1)
                                    Text(track.artist)
                                        .font(.system(size: 16))
                                        .foregroundStyle(VibeColors.textSecondary)
                                }
                                Spacer()
                                Button(action: { libraryService.toggleLike(track: track) }) {
                                    Image(systemName: libraryService.isLiked(track) ? "heart.fill" : "heart")
                                        .font(.system(size: 24))
                                        .foregroundStyle(libraryService.isLiked(track) ? VibeColors.primary : VibeColors.textSecondary)
                                        .glowEffect(radius: libraryService.isLiked(track) ? 10 : 0)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Progress slider
                        VStack(spacing: 8) {
                            Slider(value: $playerService.progress, in: 0...1) { editing in
                                isDraggingSlider = editing
                                if !editing { playerService.seek(to: playerService.progress) }
                            }
                            .tint(VibeColors.primary)

                            HStack {
                                Text(formatTime(playerService.currentTime))
                                Spacer()
                                Text("-\(formatTime(max(0, playerService.duration - playerService.currentTime)))")
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(VibeColors.textTertiary)
                        }
                        .padding(.horizontal, 20)

                        // Controls
                        HStack(spacing: 36) {
                            Button(action: { playerService.isShuffled.toggle() }) {
                                Image(systemName: "shuffle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(playerService.isShuffled ? VibeColors.primary : VibeColors.textSecondary)
                            }
                            Button(action: { playerService.skipPrevious() }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(VibeColors.textPrimary)
                            }
                            Button(action: { playerService.playPause() }) {
                                ZStack {
                                    Circle()
                                        .fill(VibeColors.primary)
                                        .frame(width: 72, height: 72)
                                        .shadow(color: VibeColors.primary.opacity(0.5), radius: 20)
                                    Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 28))
                                        .foregroundStyle(VibeColors.background)
                                }
                            }
                            Button(action: { playerService.skipNext() }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 28))
                                    .foregroundStyle(VibeColors.textPrimary)
                            }
                            Button(action: {
                                switch playerService.repeatMode {
                                case .none: playerService.repeatMode = .all
                                case .all:  playerService.repeatMode = .one
                                case .one:  playerService.repeatMode = .none
                                }
                            }) {
                                Image(systemName: playerService.repeatMode == .one ? "repeat.1" : "repeat")
                                    .font(.system(size: 20))
                                    .foregroundStyle(playerService.repeatMode != .none ? VibeColors.primary : VibeColors.textSecondary)
                            }
                        }

                        // Volume
                        HStack(spacing: 12) {
                            Image(systemName: "speaker.fill").foregroundStyle(VibeColors.textTertiary).font(.system(size: 14))
                            Slider(value: Binding(get: { Double(playerService.volume) }, set: { playerService.setVolume(Float($0)) }), in: 0...1)
                                .tint(VibeColors.primary)
                            Image(systemName: "speaker.wave.3.fill").foregroundStyle(VibeColors.textTertiary).font(.system(size: 14))
                        }
                        .padding(.horizontal, 20)

                        // Action bar
                        HStack(spacing: 32) {
                            ActionButton(icon: "text.quote", label: "Lyrics", isActive: showLyrics) {
                                showLyrics.toggle()
                                if showLyrics, let track = playerService.currentTrack {
                                    Task { lyrics = await LyricsService.shared.fetchLyrics(title: track.title, artist: track.artist) }
                                }
                            }
                            ActionButton(icon: "square.and.arrow.down", label: "Download") {
                                if let track = playerService.currentTrack {
                                    Task { await DownloadService.shared.download(track: track, quality: playerService.quality) }
                                }
                            }
                            ActionButton(icon: "music.note.list", label: "Queue") { }
                            ActionButton(icon: "airplayaudio", label: "AirPlay") { }
                        }
                        .padding(.horizontal, 20)

                        // Lyrics
                        if showLyrics {
                            LyricsView(lyrics: lyrics)
                                .padding(.horizontal, 20)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60; let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isActive ? VibeColors.primary : VibeColors.textSecondary)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(isActive ? VibeColors.primary : VibeColors.textTertiary)
            }
        }
    }
}

struct LyricsView: View {
    let lyrics: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let lyrics {
                ScrollView {
                    Text(lyrics)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(VibeColors.textPrimary)
                        .lineSpacing(8)
                        .padding(20)
                }
                .frame(maxHeight: 320)
            } else {
                HStack {
                    Spacer()
                    VibeLoader()
                    Spacer()
                }
                .padding(40)
            }
        }
        .liquidGlass(cornerRadius: 18)
    }
}
