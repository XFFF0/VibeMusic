import SwiftUI

struct FullPlayerView: View {
    @EnvironmentObject var player: PlayerService
    @EnvironmentObject var library: LibraryService
    @State private var showLyrics = false
    @State private var lyrics: String?
    @State private var loadingLyrics = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Blurred artwork background
            if let track = player.currentTrack {
                AsyncImage(url: URL(string: track.artworkURL)) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                        .blur(radius: 60).opacity(0.3).scaleEffect(1.4)
                } placeholder: { Color.clear }
                .ignoresSafeArea()
            }
            Color.vBG.opacity(0.82).ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag handle
                Capsule().fill(Color.vStroke).frame(width: 38, height: 5).padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Artwork
                        if let track = player.currentTrack {
                            ArtworkView(url: track.artworkURL, size: 300, radius: 22)
                                .shadow(color: Color.vGreen.opacity(player.isPlaying ? 0.30 : 0.08), radius: player.isPlaying ? 40 : 16)
                                .scaleEffect(player.isPlaying ? 1.0 : 0.93)
                                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: player.isPlaying)
                                .padding(.top, 24)

                            // Track info + Like
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(track.title)
                                        .font(.system(size: 22, weight: .bold)).foregroundStyle(Color.vText).lineLimit(1)
                                    HStack(spacing: 6) {
                                        Image(systemName: track.source.icon)
                                            .font(.system(size: 11)).foregroundStyle(Color.vSubtext)
                                        Text(track.artist)
                                            .font(.system(size: 16)).foregroundStyle(Color.vSubtext).lineLimit(1)
                                    }
                                }
                                Spacer()
                                Button { library.toggleLike(track) } label: {
                                    Image(systemName: library.isLiked(track) ? "heart.fill" : "heart")
                                        .font(.system(size: 24))
                                        .foregroundStyle(library.isLiked(track) ? Color.vGreen : Color.vSubtext)
                                        .greenGlow(radius: library.isLiked(track) ? 10 : 0)
                                }
                            }.padding(.horizontal, 24)

                            // Progress
                            VStack(spacing: 6) {
                                Slider(value: Binding(
                                    get: { player.progress },
                                    set: { player.seek(to: $0) }
                                ), in: 0...1)
                                .tint(Color.vGreen)
                                .padding(.horizontal, 24)

                                HStack {
                                    Text(format(player.currentTime))
                                    Spacer()
                                    Text("-\(format(max(0, player.duration - player.currentTime)))")
                                }
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(Color.vHint)
                                .padding(.horizontal, 28)
                            }

                            // Controls
                            HStack(spacing: 32) {
                                // Shuffle
                                Button { player.isShuffle.toggle() } label: {
                                    Image(systemName: "shuffle")
                                        .font(.system(size: 20))
                                        .foregroundStyle(player.isShuffle ? Color.vGreen : Color.vSubtext)
                                        .greenGlow(radius: player.isShuffle ? 8 : 0)
                                }
                                // Previous
                                Button { player.previous() } label: {
                                    Image(systemName: "backward.fill").font(.system(size: 28)).foregroundStyle(Color.vText)
                                }
                                // Play/Pause
                                Button { player.playPause() } label: {
                                    ZStack {
                                        Circle().fill(Color.vGreen).frame(width: 70, height: 70)
                                            .shadow(color: Color.vGreen.opacity(0.5), radius: 18)
                                        if player.isLoading {
                                            ProgressView().tint(Color.vBG).scaleEffect(1.2)
                                        } else {
                                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                                .font(.system(size: 26)).foregroundStyle(Color.vBG)
                                        }
                                    }
                                }
                                // Next
                                Button { player.next() } label: {
                                    Image(systemName: "forward.fill").font(.system(size: 28)).foregroundStyle(Color.vText)
                                }
                                // Repeat
                                Button {
                                    player.repeatMode = player.repeatMode == .none ? .all : player.repeatMode == .all ? .one : .none
                                } label: {
                                    Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                                        .font(.system(size: 20))
                                        .foregroundStyle(player.repeatMode != .none ? Color.vGreen : Color.vSubtext)
                                        .greenGlow(radius: player.repeatMode != .none ? 8 : 0)
                                }
                            }

                            // Volume
                            HStack(spacing: 10) {
                                Image(systemName: "speaker.fill").foregroundStyle(Color.vHint).font(.system(size: 14))
                                Slider(value: Binding(get: { Double(player.volume) }, set: { player.volume = Float($0); player.player?.volume = Float($0) }), in: 0...1)
                                    .tint(Color.vGreen)
                                Image(systemName: "speaker.wave.3.fill").foregroundStyle(Color.vHint).font(.system(size: 14))
                            }.padding(.horizontal, 28)

                            // Action row
                            HStack(spacing: 28) {
                                ActionBtn(icon: "text.quote", label: "Lyrics", active: showLyrics) {
                                    showLyrics.toggle()
                                    if showLyrics && lyrics == nil {
                                        loadingLyrics = true
                                        Task {
                                            lyrics = await LyricsService.shared.fetch(title: track.title, artist: track.artist)
                                            loadingLyrics = false
                                        }
                                    }
                                }
                                ActionBtn(icon: "square.and.arrow.down", label: "Download") {
                                    Task { await DownloadService.shared.download(track) }
                                }
                                ActionBtn(icon: "text.badge.plus", label: "Queue") {
                                    player.queue.append(track)
                                }
                                ActionBtn(icon: track.source == .youtube ? "play.rectangle.fill" : "cloud.fill",
                                          label: track.source.rawValue) { }
                            }.padding(.horizontal, 24)

                            // Lyrics panel
                            if showLyrics {
                                LyricsPanel(lyrics: lyrics, loading: loadingLyrics)
                                    .padding(.horizontal, 20)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                        Spacer(minLength: 40)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .gesture(DragGesture().onChanged { v in
            if v.translation.height > 0 { dragOffset = v.translation.height }
        }.onEnded { v in
            if v.translation.height > 100 { player.showPlayer = false }
            withAnimation(.spring()) { dragOffset = 0 }
        })
        .offset(y: dragOffset)
        .animation(.interactiveSpring(), value: dragOffset)
    }

    private func format(_ t: TimeInterval) -> String {
        let m = Int(t) / 60; let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct ActionBtn: View {
    let icon: String; let label: String; var active: Bool = false; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 20))
                    .foregroundStyle(active ? Color.vGreen : Color.vSubtext)
                    .greenGlow(radius: active ? 8 : 0)
                Text(label).font(.system(size: 10)).foregroundStyle(active ? Color.vGreen : Color.vHint)
            }
        }
    }
}

struct LyricsPanel: View {
    let lyrics: String?; let loading: Bool
    var body: some View {
        VStack {
            if loading {
                ProgressView().tint(Color.vGreen).padding(30)
            } else if let l = lyrics {
                ScrollView {
                    Text(l).font(.system(size: 16, weight: .medium)).foregroundStyle(Color.vText)
                        .lineSpacing(8).padding(20)
                }
                .frame(maxHeight: 300)
            } else {
                Text("Lyrics not available").font(.system(size: 14)).foregroundStyle(Color.vHint).padding(24)
            }
        }
        .glassCard(radius: 16)
    }
}
