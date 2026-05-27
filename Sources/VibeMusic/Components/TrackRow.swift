import SwiftUI

struct TrackRow: View {
    let track: Track
    @EnvironmentObject var playerService: AudioPlayerService
    @EnvironmentObject var libraryService: LibraryService
    @State private var showAddToPlaylist = false

    var isPlaying: Bool { playerService.currentTrack?.id == track.id }

    var body: some View {
        HStack(spacing: 14) {
            // Artwork
            ZStack {
                AsyncImage(url: URL(string: track.thumbnailURL ?? "")) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(VibeColors.surface)
                        .overlay(Image(systemName: "music.note").foregroundStyle(VibeColors.primary.opacity(0.5)))
                }
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                if isPlaying {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(VibeColors.background.opacity(0.6))
                    EqualizerBars()
                }
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title).lineLimit(1)
                    .font(.system(size: 15, weight: isPlaying ? .bold : .semibold))
                    .foregroundStyle(isPlaying ? VibeColors.primary : VibeColors.textPrimary)
                HStack(spacing: 6) {
                    if track.isDownloaded {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(VibeColors.primary)
                    }
                    Text(track.artist).lineLimit(1)
                        .font(.system(size: 13))
                        .foregroundStyle(VibeColors.textSecondary)
                    Text("·").foregroundStyle(VibeColors.textTertiary).font(.system(size: 13))
                    Text(track.source.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(VibeColors.textTertiary)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                if track.duration > 0 {
                    Text(track.formattedDuration)
                        .font(.system(size: 12))
                        .foregroundStyle(VibeColors.textTertiary)
                }
                Menu {
                    Button(action: { libraryService.toggleLike(track: track) }) {
                        Label(libraryService.isLiked(track) ? "Unlike" : "Like", systemImage: libraryService.isLiked(track) ? "heart.slash" : "heart")
                    }
                    Button(action: { showAddToPlaylist = true }) {
                        Label("Add to Playlist", systemImage: "music.note.list")
                    }
                    Button(action: {
                        Task { await DownloadService.shared.download(track: track, quality: .high) }
                    }) {
                        Label("Download", systemImage: "arrow.down.circle")
                    }
                    Button(action: {
                        playerService.queue.append(track)
                    }) {
                        Label("Add to Queue", systemImage: "text.badge.plus")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundStyle(VibeColors.textTertiary)
                        .frame(width: 30, height: 30)
                }
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showAddToPlaylist) {
            AddToPlaylistSheet(track: track)
        }
    }
}

struct EqualizerBars: View {
    @State private var heights: [CGFloat] = [8, 16, 12, 20, 10]
    let timer = Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                Capsule()
                    .fill(VibeColors.primary)
                    .frame(width: 3, height: heights[i])
            }
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                heights = (0..<5).map { _ in CGFloat.random(in: 6...22) }
            }
        }
    }
}

struct TrackDetailSheet: View {
    let track: Track
    @EnvironmentObject var playerService: AudioPlayerService
    @EnvironmentObject var libraryService: LibraryService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    AsyncImage(url: URL(string: track.thumbnailURL ?? "")) { img in
                        img.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(VibeColors.surface)
                    }
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: VibeColors.primary.opacity(0.3), radius: 30)
                    .padding(.top, 20)

                    VStack(spacing: 6) {
                        Text(track.title).font(.system(size: 22, weight: .bold)).foregroundStyle(VibeColors.textPrimary)
                        Text(track.artist).font(.system(size: 16)).foregroundStyle(VibeColors.textSecondary)
                        Text(track.album).font(.system(size: 14)).foregroundStyle(VibeColors.textTertiary)
                    }

                    HStack(spacing: 16) {
                        ActionSheetButton(icon: "play.fill", label: "Play") {
                            playerService.play(track: track); dismiss()
                        }
                        ActionSheetButton(icon: libraryService.isLiked(track) ? "heart.fill" : "heart",
                                          label: libraryService.isLiked(track) ? "Liked" : "Like",
                                          isActive: libraryService.isLiked(track)) {
                            libraryService.toggleLike(track: track)
                        }
                        ActionSheetButton(icon: "arrow.down.circle", label: "Download") {
                            Task { await DownloadService.shared.download(track: track) }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() }.foregroundStyle(VibeColors.primary) } }
            .background(VibeColors.background.ignoresSafeArea())
        }
        .preferredColorScheme(.dark)
    }
}

struct ActionSheetButton: View {
    let icon: String; let label: String; var isActive: Bool = false; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 22)).foregroundStyle(isActive ? VibeColors.primary : VibeColors.textPrimary)
                Text(label).font(.system(size: 12)).foregroundStyle(isActive ? VibeColors.primary : VibeColors.textSecondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16).liquidGlass(cornerRadius: 14)
        }
    }
}

struct AddToPlaylistSheet: View {
    let track: Track
    @EnvironmentObject var libraryService: LibraryService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List(libraryService.playlists) { playlist in
                Button(action: {
                    libraryService.addTrack(track, to: playlist.id)
                    dismiss()
                }) {
                    HStack {
                        Text(playlist.name).foregroundStyle(VibeColors.textPrimary)
                        Spacer()
                        Text("\(playlist.trackCount) songs").foregroundStyle(VibeColors.textTertiary).font(.system(size: 13))
                    }
                }
                .listRowBackground(VibeColors.surface)
            }
            .scrollContentBackground(.hidden)
            .background(VibeColors.background)
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Cancel") { dismiss() }.foregroundStyle(VibeColors.primary) } }
        }
        .preferredColorScheme(.dark)
    }
}
