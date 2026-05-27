import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var libraryService: LibraryService
    @EnvironmentObject var playerService: AudioPlayerService
    @State private var showCreatePlaylist = false
    @State private var newPlaylistName = ""
    @State private var selectedPlaylist: Playlist?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Library")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(VibeColors.textPrimary)
                Spacer()
                Button(action: { showCreatePlaylist = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(VibeColors.primary)
                        .glowEffect(radius: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 16)
            .background(VibeColors.background)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Stats card
                    HStack(spacing: 0) {
                        StatPill(value: "\(libraryService.likedTracks.count)", label: "Liked")
                        Divider().background(VibeColors.glassStroke).frame(height: 30)
                        StatPill(value: "\(libraryService.playlists.count)", label: "Playlists")
                        Divider().background(VibeColors.glassStroke).frame(height: 30)
                        StatPill(value: "\(libraryService.downloadedTracks.count)", label: "Downloaded")
                    }
                    .liquidGlass(cornerRadius: 16)
                    .padding(.horizontal, 20)

                    // Liked songs shortcut
                    if !libraryService.likedTracks.isEmpty {
                        Button(action: { selectedPlaylist = Playlist(id: "liked", name: "Liked Songs", tracks: libraryService.likedTracks, createdAt: Date(), updatedAt: Date()) }) {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(LinearGradient(colors: [VibeColors.primary, VibeColors.primaryGlow], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 52, height: 52)
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.white)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Liked Songs")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(VibeColors.textPrimary)
                                    Text("\(libraryService.likedTracks.count) songs")
                                        .font(.system(size: 13))
                                        .foregroundStyle(VibeColors.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(VibeColors.textTertiary)
                            }
                            .padding(14)
                            .liquidGlass(cornerRadius: 16)
                        }
                        .padding(.horizontal, 20)
                    }

                    // Playlists
                    if !libraryService.playlists.isEmpty {
                        VStack(spacing: 8) {
                            HStack {
                                Text("Playlists").font(.system(size: 18, weight: .bold)).foregroundStyle(VibeColors.textPrimary)
                                Spacer()
                            }
                            ForEach(libraryService.playlists) { playlist in
                                PlaylistRow(playlist: playlist)
                                    .onTapGesture { selectedPlaylist = playlist }
                                    .contextMenu {
                                        Button("Play All") {
                                            if let first = playlist.tracks.first {
                                                playerService.play(track: first, queue: playlist.tracks)
                                            }
                                        }
                                        Button("Rename") { }
                                        Button("Delete", role: .destructive) {
                                            libraryService.deletePlaylist(playlist.id)
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    if libraryService.playlists.isEmpty && libraryService.likedTracks.isEmpty {
                        EmptyLibraryView(onCreatePlaylist: { showCreatePlaylist = true })
                    }

                    Spacer(minLength: 160)
                }
                .padding(.top, 8)
            }
        }
        .background(VibeColors.background.ignoresSafeArea())
        .sheet(item: $selectedPlaylist) { playlist in
            PlaylistDetailView(playlist: playlist)
        }
        .alert("New Playlist", isPresented: $showCreatePlaylist) {
            TextField("Playlist name", text: $newPlaylistName)
            Button("Create") {
                if !newPlaylistName.isEmpty {
                    _ = libraryService.createPlaylist(name: newPlaylistName)
                    newPlaylistName = ""
                }
            }
            Button("Cancel", role: .cancel) { newPlaylistName = "" }
        }
    }
}

struct StatPill: View {
    let value: String; let label: String
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 20, weight: .bold)).foregroundStyle(VibeColors.primary)
            Text(label).font(.system(size: 12)).foregroundStyle(VibeColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }
}

struct PlaylistRow: View {
    let playlist: Playlist
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(VibeColors.surface).frame(width: 52, height: 52)
                if playlist.tracks.isEmpty {
                    Image(systemName: "music.note.list").font(.system(size: 20)).foregroundStyle(VibeColors.primary.opacity(0.5))
                } else {
                    LazyVGrid(columns: [.init(.flexible(), spacing: 1), .init(.flexible(), spacing: 1)], spacing: 1) {
                        ForEach(playlist.tracks.prefix(4)) { t in
                            AsyncImage(url: URL(string: t.thumbnailURL ?? "")) { img in img.resizable().aspectRatio(contentMode: .fill) } placeholder: { VibeColors.surface }
                                .frame(width: 25, height: 25).clipped()
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .frame(width: 52, height: 52)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(playlist.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(VibeColors.textPrimary)
                Text("\(playlist.trackCount) songs").font(.system(size: 13)).foregroundStyle(VibeColors.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(VibeColors.textTertiary).font(.system(size: 13))
        }
        .padding(12)
        .liquidGlass(cornerRadius: 14)
    }
}

struct EmptyLibraryView: View {
    let onCreatePlaylist: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)
            Image(systemName: "music.note.list").font(.system(size: 56)).foregroundStyle(VibeColors.primary.opacity(0.4))
            Text("Your library is empty").font(.system(size: 20, weight: .semibold)).foregroundStyle(VibeColors.textSecondary)
            Text("Create playlists and like songs to build your collection").font(.system(size: 14)).foregroundStyle(VibeColors.textTertiary).multilineTextAlignment(.center)
            Button(action: onCreatePlaylist) {
                Label("Create Playlist", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(VibeColors.background)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(VibeColors.primary)
                    .clipShape(Capsule())
                    .glowEffect()
            }
        }
        .padding(.horizontal, 40)
    }
}

struct PlaylistDetailView: View {
    let playlist: Playlist
    @EnvironmentObject var playerService: AudioPlayerService
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(playlist.tracks) { track in
                        TrackRow(track: track).onTapGesture {
                            playerService.play(track: track, queue: playlist.tracks)
                        }
                        .padding(.horizontal, 20)
                        Divider().background(VibeColors.glassStroke).padding(.leading, 86)
                    }
                    Spacer(minLength: 80)
                }
                .padding(.top, 8)
            }
            .navigationTitle(playlist.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(VibeColors.primary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !playlist.tracks.isEmpty {
                        Button(action: {
                            playerService.play(track: playlist.tracks[0], queue: playlist.tracks)
                        }) {
                            Label("Play All", systemImage: "play.fill").foregroundStyle(VibeColors.primary)
                        }
                    }
                }
            }
            .background(VibeColors.background.ignoresSafeArea())
        }
        .preferredColorScheme(.dark)
    }
}
