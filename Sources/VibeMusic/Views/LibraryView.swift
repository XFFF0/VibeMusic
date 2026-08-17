import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var player: PlayerService
    @EnvironmentObject var library: LibraryService
    @State private var showCreate = false
    @State private var newName = ""
    @State private var selected: Playlist?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Text("Library").font(.system(size: 28, weight: .black)).foregroundStyle(Color.vText)
                    Spacer()
                    Button { showCreate = true } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 26)).foregroundStyle(Color.vGreen).greenGlow(radius: 8)
                    }
                }
                .padding(.horizontal, 20).padding(.top, 60)

                // Stats
                HStack(spacing: 0) {
                    StatCell(n: "\(library.liked.count)", label: "Liked")
                    Divider().background(Color.vStroke).frame(height: 28)
                    StatCell(n: "\(library.playlists.count)", label: "Playlists")
                    Divider().background(Color.vStroke).frame(height: 28)
                    StatCell(n: "\(library.downloads.count)", label: "Downloads")
                }
                .glassCard(radius: 14)
                .padding(.horizontal, 20)

                // Liked Songs shortcut
                if !library.liked.isEmpty {
                    Button {
                        if let f = library.liked.first { player.play(track: f, queue: library.liked) }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(LinearGradient(colors: [Color.vGreen, Color.vGreenDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "heart.fill").font(.system(size: 22)).foregroundStyle(.white)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Liked Songs").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.vText)
                                Text("\(library.liked.count) songs").font(.system(size: 13)).foregroundStyle(Color.vSubtext)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Color.vHint).font(.system(size: 13))
                        }
                        .padding(14).glassCard(radius: 14)
                    }
                    .padding(.horizontal, 20)
                }

                // Downloads shortcut
                if !library.downloads.isEmpty {
                    Button {
                        if let f = library.downloads.first { player.play(track: f, queue: library.downloads) }
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.vSurface).frame(width: 52, height: 52)
                                Image(systemName: "arrow.down.circle.fill").font(.system(size: 28)).foregroundStyle(Color.vGreen)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Downloads").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.vText)
                                Text("\(library.downloads.count) songs · Offline").font(.system(size: 13)).foregroundStyle(Color.vSubtext)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(Color.vHint).font(.system(size: 13))
                        }
                        .padding(14).glassCard(radius: 14)
                    }
                    .padding(.horizontal, 20)
                }

                // Playlists
                if !library.playlists.isEmpty {
                    Text("Playlists").font(.system(size: 19, weight: .bold)).foregroundStyle(Color.vText).padding(.horizontal, 20)
                    VStack(spacing: 8) {
                        ForEach(library.playlists) { pl in
                            Button { selected = pl } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8).fill(Color.vSurface).frame(width: 50, height: 50)
                                        if pl.tracks.isEmpty {
                                            Image(systemName: "music.note.list").foregroundStyle(Color.vGreen.opacity(0.5))
                                        } else {
                                            ArtworkView(url: pl.tracks[0].artworkURL, size: 50, radius: 8)
                                        }
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(pl.name).font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.vText)
                                        Text("\(pl.tracks.count) songs").font(.system(size: 13)).foregroundStyle(Color.vSubtext)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(Color.vHint).font(.system(size: 13))
                                }
                                .padding(12).glassCard(radius: 12)
                            }
                            .contextMenu {
                                Button("Delete", role: .destructive) { library.deletePlaylist(pl.id) }
                            }
                        }
                    }.padding(.horizontal, 20)
                }

                if library.liked.isEmpty && library.playlists.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "music.note.list").font(.system(size: 48)).foregroundStyle(Color.vHint)
                        Text("Your library is empty").font(.system(size: 18, weight: .semibold)).foregroundStyle(Color.vSubtext)
                        Text("Like songs or create a playlist").font(.system(size: 13)).foregroundStyle(Color.vHint)
                    }.frame(maxWidth: .infinity).padding(.top, 60)
                }

                Spacer(minLength: 150)
            }
        }
        .background(Color.vBG.ignoresSafeArea())
        .sheet(item: $selected) { pl in PlaylistDetailView(playlist: pl) }
        .alert("New Playlist", isPresented: $showCreate) {
            TextField("Playlist name", text: $newName)
            Button("Create") { if !newName.isEmpty { _ = library.createPlaylist(name: newName); newName = "" } }
            Button("Cancel", role: .cancel) { newName = "" }
        }
    }
}

struct StatCell: View {
    let n: String; let label: String
    var body: some View {
        VStack(spacing: 3) {
            Text(n).font(.system(size: 22, weight: .bold)).foregroundStyle(Color.vGreen)
            Text(label).font(.system(size: 12)).foregroundStyle(Color.vSubtext)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
    }
}

struct PlaylistDetailView: View {
    let playlist: Playlist
    @EnvironmentObject var player: PlayerService
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(playlist.tracks) { track in
                        TrackRow(track: track).onTapGesture { player.play(track: track, queue: playlist.tracks) }
                            .padding(.horizontal, 20)
                        Divider().background(Color.vStroke).padding(.leading, 82)
                    }
                    Spacer(minLength: 80)
                }
            }
            .background(Color.vBG.ignoresSafeArea())
            .navigationTitle(playlist.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Done") { dismiss() }.foregroundStyle(Color.vGreen) } }
        }.preferredColorScheme(.dark)
    }
}
