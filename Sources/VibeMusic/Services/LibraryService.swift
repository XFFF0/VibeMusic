import Foundation
import Combine

@MainActor
class LibraryService: ObservableObject {
    static let shared = LibraryService()

    @Published var playlists: [Playlist] = []
    @Published var likedTracks: [Track] = []
    @Published var recentlyPlayed: [Track] = []
    @Published var downloadedTracks: [Track] = []

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private var playlistsURL: URL { documentsURL.appendingPathComponent("playlists.json") }
    private var likedURL: URL     { documentsURL.appendingPathComponent("liked.json") }
    private var recentURL: URL    { documentsURL.appendingPathComponent("recent.json") }

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private init() { loadAll() }

    // MARK: - Playlists
    func createPlaylist(name: String, description: String? = nil) -> Playlist {
        let p = Playlist(id: UUID().uuidString, name: name, description: description,
                         coverURL: nil, tracks: [], createdAt: Date(), updatedAt: Date())
        playlists.append(p)
        save(playlists, to: playlistsURL)
        return p
    }

    func addTrack(_ track: Track, to playlistID: String) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        guard !playlists[idx].tracks.contains(where: { $0.id == track.id }) else { return }
        playlists[idx].tracks.append(track)
        playlists[idx].updatedAt = Date()
        save(playlists, to: playlistsURL)
    }

    func removeTrack(_ trackID: String, from playlistID: String) {
        guard let idx = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        playlists[idx].tracks.removeAll { $0.id == trackID }
        save(playlists, to: playlistsURL)
    }

    func deletePlaylist(_ id: String) {
        playlists.removeAll { $0.id == id }
        save(playlists, to: playlistsURL)
    }

    func renamePlaylist(_ id: String, newName: String) {
        guard let idx = playlists.firstIndex(where: { $0.id == id }) else { return }
        playlists[idx].name = newName
        save(playlists, to: playlistsURL)
    }

    // MARK: - Liked Tracks
    func toggleLike(track: Track) {
        if isLiked(track) {
            likedTracks.removeAll { $0.id == track.id }
        } else {
            likedTracks.insert(track, at: 0)
        }
        save(likedTracks, to: likedURL)
    }

    func isLiked(_ track: Track) -> Bool {
        likedTracks.contains { $0.id == track.id }
    }

    // MARK: - Recently Played
    func addToRecent(_ track: Track) {
        recentlyPlayed.removeAll { $0.id == track.id }
        recentlyPlayed.insert(track, at: 0)
        if recentlyPlayed.count > 50 { recentlyPlayed = Array(recentlyPlayed.prefix(50)) }
        save(recentlyPlayed, to: recentURL)
    }

    // MARK: - Downloads
    func markDownloaded(trackID: String, localPath: String) {
        if let idx = likedTracks.firstIndex(where: { $0.id == trackID }) {
            likedTracks[idx].isDownloaded = true
            likedTracks[idx].localPath = localPath
        }
        for pidx in playlists.indices {
            for tidx in playlists[pidx].tracks.indices {
                if playlists[pidx].tracks[tidx].id == trackID {
                    playlists[pidx].tracks[tidx].isDownloaded = true
                    playlists[pidx].tracks[tidx].localPath = localPath
                }
            }
        }
        save(likedTracks, to: likedURL)
        save(playlists, to: playlistsURL)
    }

    func localPath(for trackID: String) -> String? {
        likedTracks.first(where: { $0.id == trackID })?.localPath
    }

    // MARK: - Cloud Sync (Google Drive JSON)
    func syncFromCloud() {
        // Sync logic with Google Drive API using auth token
        // For now, local persistence is used; full Drive sync can be added
    }

    func clearUserData() {
        playlists = []
        likedTracks = []
        recentlyPlayed = []
        save(playlists, to: playlistsURL)
        save(likedTracks, to: likedURL)
        save(recentlyPlayed, to: recentURL)
    }

    // MARK: - Persistence
    private func loadAll() {
        playlists      = load(from: playlistsURL) ?? []
        likedTracks    = load(from: likedURL) ?? []
        recentlyPlayed = load(from: recentURL) ?? []
    }

    private func save<T: Encodable>(_ value: T, to url: URL) {
        if let data = try? encoder.encode(value) { try? data.write(to: url) }
    }

    private func load<T: Decodable>(from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }
}
