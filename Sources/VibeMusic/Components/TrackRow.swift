import SwiftUI

// MARK: - Track Row
struct TrackRow: View {
    let track: Track
    @EnvironmentObject var player: PlayerService
    @EnvironmentObject var library: LibraryService
    @State private var showAdd = false

    var isPlaying: Bool { player.currentTrack?.id == track.id }

    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            ZStack {
                ArtworkView(url: track.artworkURL, size: 52, radius: 8)
                if isPlaying {
                    RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.55))
                    WaveformBars(isAnimating: player.isPlaying, barCount: 4)
                }
            }.frame(width: 52, height: 52)

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: 15, weight: isPlaying ? .bold : .semibold))
                    .foregroundStyle(isPlaying ? Color.vGreen : Color.vText)
                    .lineLimit(1)
                HStack(spacing: 5) {
                    if track.isDownloaded {
                        Image(systemName: "arrow.down.circle.fill").font(.system(size: 10)).foregroundStyle(Color.vGreen)
                    }
                    Image(systemName: track.source.icon).font(.system(size: 10)).foregroundStyle(Color.vHint)
                    Text(track.artist).font(.system(size: 13)).foregroundStyle(Color.vSubtext).lineLimit(1)
                }
            }

            Spacer()

            // Duration + menu
            HStack(spacing: 10) {
                if track.duration > 0 {
                    Text(track.formattedDuration).font(.system(size: 12, design: .monospaced)).foregroundStyle(Color.vHint)
                }
                Menu {
                    Button { library.toggleLike(track) } label: {
                        Label(library.isLiked(track) ? "Unlike" : "Like",
                              systemImage: library.isLiked(track) ? "heart.slash" : "heart")
                    }
                    Button { showAdd = true } label: { Label("Add to Playlist", systemImage: "music.note.list") }
                    Button { DownloadService.shared.download(track) } label: {
                        Label("Download", systemImage: "arrow.down.circle")
                    }
                    Button {
                        if !player.queue.contains(where: { $0.id == track.id }) { player.queue.append(track) }
                    } label: { Label("Add to Queue", systemImage: "text.badge.plus") }
                } label: {
                    Image(systemName: "ellipsis").font(.system(size: 16)).foregroundStyle(Color.vHint)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .padding(.vertical, 9)
        .sheet(isPresented: $showAdd) { AddToPlaylistSheet(track: track) }
    }
}

// MARK: - Artwork
struct ArtworkView: View {
    let url: String; let size: CGFloat; let radius: CGFloat
    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let img):
                img.resizable().aspectRatio(contentMode: .fill)
            case .failure(_):
                ZStack {
                    Color.vSurface
                    Image(systemName: "music.note").font(.system(size: size * 0.3)).foregroundStyle(Color.vGreen.opacity(0.5))
                }
            default:
                ZStack {
                    Color.vSurface
                    ProgressView().tint(Color.vGreen).scaleEffect(0.7)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

// MARK: - Add to Playlist sheet
struct AddToPlaylistSheet: View {
    let track: Track
    @EnvironmentObject var library: LibraryService
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                if library.playlists.isEmpty {
                    Text("No playlists yet. Create one in Library.")
                        .foregroundStyle(Color.vSubtext).listRowBackground(Color.vSurface)
                } else {
                    ForEach(library.playlists) { pl in
                        Button {
                            library.addTrack(track, to: pl.id); dismiss()
                        } label: {
                            HStack {
                                Text(pl.name).foregroundStyle(Color.vText)
                                Spacer()
                                Text("\(pl.tracks.count)").foregroundStyle(Color.vHint).font(.system(size: 13))
                            }
                        }.listRowBackground(Color.vSurface)
                    }
                }
            }
            .scrollContentBackground(.hidden).background(Color.vBG)
            .navigationTitle("Add to Playlist").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Cancel") { dismiss() }.foregroundStyle(Color.vGreen) } }
        }.preferredColorScheme(.dark)
    }
}
