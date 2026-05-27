import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject var playerService: AudioPlayerService
    @State private var showFullPlayer = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        if let track = playerService.currentTrack {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: track.thumbnailURL ?? "")) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(VibeColors.surface)
                        .overlay(Image(systemName: "music.note").foregroundStyle(VibeColors.primary))
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title).lineLimit(1)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(VibeColors.textPrimary)
                    Text(track.artist).lineLimit(1)
                        .font(.system(size: 12))
                        .foregroundStyle(VibeColors.textSecondary)
                }

                Spacer()

                HStack(spacing: 18) {
                    Button(action: { playerService.playPause() }) {
                        Image(systemName: playerService.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(VibeColors.primary)
                            .glowEffect(radius: 8)
                    }
                    Button(action: { playerService.skipNext() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(VibeColors.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 18)
                        .fill(VibeColors.glass)
                    // Progress indicator at bottom
                    GeometryReader { geo in
                        Rectangle()
                            .fill(VibeColors.primary.opacity(0.5))
                            .frame(width: geo.size.width * playerService.progress, height: 2)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .clipShape(RoundedRectangle(cornerRadius: 1))
                    }
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(VibeColors.glassStroke, lineWidth: 1)
                }
            )
            .shadow(color: VibeColors.primary.opacity(0.12), radius: 20)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { v in if v.translation.height < 0 { dragOffset = v.translation.height } }
                    .onEnded { v in
                        if v.translation.height < -50 { showFullPlayer = true }
                        withAnimation(.spring()) { dragOffset = 0 }
                    }
            )
            .onTapGesture { showFullPlayer = true }
            .sheet(isPresented: $showFullPlayer) { FullPlayerView() }
        }
    }
}
