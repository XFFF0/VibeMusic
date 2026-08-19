import Foundation

class SoundCloudService {
    static let shared = SoundCloudService()
    private init() {}

    // Known working client IDs (rotate if one stops working)
    private let clientIDs = [
        "a3e059563d7fd3372b49429ad9abd52b",
        "iZIs9mchVcX5lhVRyQGGAYlNPVldzAoX",
        "2t9loNQH90kzJcsFCODdigxfp325aq4z",
        "fDoItMDbsbZz8dY16ZzARCZmzgHBPotA"
    ]

    func search(query: String) async -> [Track] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        for cid in clientIDs {
            if let tracks = await doSearch(clientID: cid, query: encoded), !tracks.isEmpty {
                return tracks
            }
        }
        return []
    }

    private func doSearch(clientID: String, query: String) async -> [Track]? {
        guard let url = URL(string:
            "https://api.soundcloud.com/tracks?q=\(query)&limit=20&client_id=\(clientID)&linked_partitioning=1"
        ) else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let items = try JSONDecoder().decode([SCTrack].self, from: data)
            return items.compactMap { t in
                guard let stream = t.stream_url else { return nil }
                let art = t.artwork_url?.replacingOccurrences(of: "large", with: "t500x500") ?? ""
                return Track(
                    id: "sc_\(t.id)",
                    title: t.title,
                    artist: t.user.username,
                    album: "SoundCloud",
                    duration: TimeInterval(t.duration / 1000),
                    artworkURL: art,
                    streamURL: "\(stream)?client_id=\(clientID)",
                    source: .soundcloud
                )
            }
        } catch { return nil }
    }

    func resolveStreamURL(track: Track) async -> String? {
        guard let str = track.streamURL else { return nil }
        if str.contains("media.sndcdn.com") || str.contains(".mp3") { return str }
        guard let url = URL(string: str) else { return str }
        do {
            let (_, resp) = try await URLSession.shared.data(from: url)
            return (resp as? HTTPURLResponse)?.url?.absoluteString ?? str
        } catch { return str }
    }

    struct SCTrack: Codable {
        let id: Int; let title: String; let duration: Int
        let artwork_url: String?; let stream_url: String?
        let user: SCUser
    }
    struct SCUser: Codable { let username: String }
}
