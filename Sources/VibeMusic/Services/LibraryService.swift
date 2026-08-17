import Foundation

@MainActor
class LibraryService: ObservableObject {
    static let shared = LibraryService()

    @Published var liked:    [Track]    = []
    @Published var recent:   [Track]    = []
    @Published var playlists:[Playlist] = []
    @Published var downloads:[Track]    = []

    private let enc = JSONEncoder()
    private let dec = JSONDecoder()
    private var docs: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }

    private init() { load() }

    // MARK: - Liked
    func toggleLike(_ track: Track) {
        if isLiked(track) { liked.removeAll { $0.id == track.id } }
        else { liked.insert(track, at: 0) }
        save(liked, "liked.json")
    }
    func isLiked(_ track: Track) -> Bool { liked.contains { $0.id == track.id } }

    // MARK: - Recent
    func addRecent(_ track: Track) {
        recent.removeAll { $0.id == track.id }
        recent.insert(track, at: 0)
        if recent.count > 50 { recent = Array(recent.prefix(50)) }
        save(recent, "recent.json")
    }

    // MARK: - Playlists
    func createPlaylist(name: String) -> Playlist {
        let p = Playlist(name: name)
        playlists.append(p)
        save(playlists, "playlists.json")
        return p
    }
    func addTrack(_ track: Track, to id: String) {
        guard let i = playlists.firstIndex(where: { $0.id == id }) else { return }
        guard !playlists[i].tracks.contains(where: { $0.id == track.id }) else { return }
        playlists[i].tracks.append(track)
        save(playlists, "playlists.json")
    }
    func removeTrack(_ trackID: String, from id: String) {
        guard let i = playlists.firstIndex(where: { $0.id == id }) else { return }
        playlists[i].tracks.removeAll { $0.id == trackID }
        save(playlists, "playlists.json")
    }
    func deletePlaylist(_ id: String) {
        playlists.removeAll { $0.id == id }
        save(playlists, "playlists.json")
    }

    // MARK: - Downloads
    func markDownloaded(_ id: String, path: String) {
        func update(_ t: inout Track) { if t.id == id { t.isDownloaded = true; t.localPath = path } }
        for i in liked.indices    { update(&liked[i]) }
        for p in playlists.indices { for t in playlists[p].tracks.indices { update(&playlists[p].tracks[t]) } }
        if !downloads.contains(where: { $0.id == id }),
           let track = liked.first(where: { $0.id == id }) { downloads.append(track) }
        save(liked, "liked.json"); save(playlists, "playlists.json"); save(downloads, "downloads.json")
    }

    // MARK: - Persistence
    private func load() {
        liked     = read("liked.json")     ?? []
        recent    = read("recent.json")    ?? []
        playlists = read("playlists.json") ?? []
        downloads = read("downloads.json") ?? []
    }
    private func save<T: Encodable>(_ v: T, _ name: String) {
        if let d = try? enc.encode(v) { try? d.write(to: docs.appendingPathComponent(name)) }
    }
    private func read<T: Decodable>(_ name: String) -> T? {
        guard let d = try? Data(contentsOf: docs.appendingPathComponent(name)) else { return nil }
        return try? dec.decode(T.self, from: d)
    }
}
