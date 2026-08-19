import Foundation

class SoundCloudService {
    static let shared = SoundCloudService()
    private init() {}

    // SoundCloud client IDs rotate frequently - using multiple known working ones
    private let clientIDs = [
        "a3e059563d7fd3372b49429ad9abd52b",
        "iZIs9mchVcX5lhVRyQGGAYlNPVldzAoX",
        "2t9loNQH90kzJcsFCODdigxfp325aq4z"
    ]

    func search(query: String) async -> [Track] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        for cid in clientIDs {
            if let tracks = await searchWithClientID(cid, query: encoded) {
                return tracks
            }
        }
        return []
    }

    private func searchWithClientID(_ clientID: String, query: String) async -> [Track]? {
        guard let url = URL(string: "https://api.soundcloud.com/tracks?q=\(query)&limit=20&client_id=\(clientID)") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 8)
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let items = try JSONDecoder().decode([SCTrack].self, from: data)
            guard !items.isEmpty else { return nil }
            return items.compactMap { t in
                guard let streamURL = t.stream_url else { return nil }
                let art = t.artwork_url?.replacingOccurrences(of: "large", with: "t500x500") ?? ""
                return Track(
                    id: "sc_\(t.id)",
                    title: t.title,
                    artist: t.user.username,
                    album: "SoundCloud",
                    duration: TimeInterval(t.duration / 1000),
                    artworkURL: art,
                    streamURL: "\(streamURL)?client_id=\(clientID)",
                    source: .soundcloud
                )
            }
        } catch { return nil }
    }

    func resolveStreamURL(track: Track) async -> String? {
        guard let str = track.streamURL, let url = URL(string: str) else { return nil }
        // Direct URL - just return it
        if str.contains("media.sndcdn.com") || str.contains(".mp3") { return str }
        do {
            // Follow redirect to get final stream URL
            var req = URLRequest(url: url, timeoutInterval: 8)
            req.httpMethod = "GET"
            let (_, resp) = try await URLSession.shared.data(for: req)
            return (resp as? HTTPURLResponse)?.url?.absoluteString ?? str
        } catch { return str }
    }

    struct SCTrack: Codable {
        let id: Int
        let title: String
        let duration: Int
        let artwork_url: String?
        let stream_url: String?
        let user: SCUser
    }
    struct SCUser: Codable { let username: String }
}
