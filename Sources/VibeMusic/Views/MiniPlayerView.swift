import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var player: PlayerService
    @EnvironmentObject var library: LibraryService

    var body: some View {
        if let track = player.currentTrack {
            HStack(spacing: 12) {
                ArtworkView(url: track.artworkURL, size: 44, radius: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title).font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.vText).lineLimit(1)
                    Text(track.artist).font(.system(size: 12))
                        .foregroundStyle(Color.vSubtext).lineLimit(1)
                }

                Spacer()

                // Like
                Button { library.toggleLike(track) } label: {
                    Image(systemName: library.isLiked(track) ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundStyle(library.isLiked(track) ? Color.vGreen : Color.vSubtext)
                }

                // Play/Pause
                Button { player.playPause() } label: {
                    if player.isLoading {
                        ProgressView().tint(Color.vGreen).frame(width: 28, height: 28)
                    } else {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Color.vGreen).greenGlow(radius: 6)
                    }
                }

                // Next
                Button { player.next() } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 18)).foregroundStyle(Color.vSubtext)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(
                ZStack {
                    Rectangle().fill(.ultraThinMaterial)
                    // Progress bar at bottom
                    GeometryReader { geo in
                        Rectangle().fill(Color.vGreen.opacity(0.6))
                            .frame(width: geo.size.width * player.progress, height: 2)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    Rectangle().stroke(Color.vStroke, lineWidth: 0.5)
                }
            )
            .onTapGesture { player.showPlayer = true }
        }
    }
}
