import Foundation

class SoundCloudService {
    static let shared = SoundCloudService()
    private init() {}

    // SoundCloud unofficial search via their mobile/web API
    // Uses the same endpoint the SoundCloud website uses
    private let baseURL = "https://api-v2.soundcloud.com"

    // These client_ids work with api-v2 (more stable than old api)
    private let clientIDs = [
        "a3e059563d7fd3372b49429ad9abd52b",
        "iZIs9mchVcX5lhVRyQGGAYlNPVldzAoX",
        "2t9loNQH90kzJcsFCODdigxfp325aq4z",
        "fDoItMDbsbZz8dY16ZzARCZmzgHBPotA",
        "LBCcHmRB8XSStWL6wKH2HPACspoor9JE"
    ]

    // MARK: - Search
    func search(query: String) async -> [Track] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query

        // Try api-v2 (newer endpoint)
        for cid in clientIDs {
            if let tracks = await searchV2(clientID: cid, query: encoded), !tracks.isEmpty {
                return tracks
            }
        }

        // Fallback: old api
        for cid in clientIDs {
            if let tracks = await searchV1(clientID: cid, query: encoded), !tracks.isEmpty {
                return tracks
            }
        }

        return []
    }

    // api-v2.soundcloud.com (same as website uses)
    private func searchV2(clientID: String, query: String) async -> [Track]? {
        let urlStr = "\(baseURL)/search/tracks?q=\(query)&client_id=\(clientID)&limit=20&offset=0"
        guard let url = URL(string: urlStr) else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let result = try JSONDecoder().decode(SCV2Response.self, from: data)
            return result.collection.compactMap { t in
                let art = t.artwork_url?.replacingOccurrences(of: "large", with: "t500x500") ?? ""
                // Build stream URL using media transcodings
                let streamURL = t.media?.transcodings?.first(where: {
                    $0.format?.protocol == "progressive"
                })?.url.map { "\($0)?client_id=\(clientID)" }
                ?? t.media?.transcodings?.first?.url.map { "\($0)?client_id=\(clientID)" }

                return Track(
                    id: "sc_\(t.id)",
                    title: t.title,
                    artist: t.user.username,
                    album: "SoundCloud",
                    duration: TimeInterval((t.duration ?? 0) / 1000),
                    artworkURL: art,
                    streamURL: streamURL ?? "",
                    source: .soundcloud
                )
            }
        } catch { return nil }
    }

    // Old api.soundcloud.com
    private func searchV1(clientID: String, query: String) async -> [Track]? {
        let urlStr = "https://api.soundcloud.com/tracks?q=\(query)&limit=20&client_id=\(clientID)"
        guard let url = URL(string: urlStr) else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 8)
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let items = try JSONDecoder().decode([SCV1Track].self, from: data)
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

    // MARK: - Stream URL resolution
    func resolveStreamURL(track: Track) async -> String? {
        guard let str = track.streamURL, !str.isEmpty else { return nil }

        // Already a direct media URL
        if str.contains("media.sndcdn.com") || str.contains(".mp3") { return str }

        // Resolve transcoding URL to actual stream
        guard let url = URL(string: str) else { return str }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)", forHTTPHeaderField: "User-Agent")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return str }
            // Response contains {"url": "https://media.sndcdn.com/..."}
            if let json = try? JSONDecoder().decode([String: String].self, from: data),
               let streamURL = json["url"] {
                return streamURL
            }
            return (resp as? HTTPURLResponse)?.url?.absoluteString ?? str
        } catch { return str }
    }

    // MARK: - Models
    struct SCV2Response: Codable {
        let collection: [SCV2Track]
    }

    struct SCV2Track: Codable {
        let id: Int
        let title: String
        let duration: Int?
        let artwork_url: String?
        let user: SCUser
        let media: SCMedia?
    }

    struct SCMedia: Codable {
        let transcodings: [SCTranscoding]?
    }

    struct SCTranscoding: Codable {
        let url: String?
        let format: SCFormat?
    }

    struct SCFormat: Codable {
        let `protocol`: String?
    }

    struct SCV1Track: Codable {
        let id: Int
        let title: String
        let duration: Int
        let artwork_url: String?
        let stream_url: String?
        let user: SCUser
    }

    struct SCUser: Codable { let username: String }
}
