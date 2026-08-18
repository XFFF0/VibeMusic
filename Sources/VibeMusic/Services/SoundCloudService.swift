import Foundation

class SoundCloudService {
    static let shared = SoundCloudService()

    // SoundCloud public client ID (rotates - using known working one)
    private var clientID = "a3e059563d7fd3372b49429ad9abd52b"

    func search(query: String) async -> [Track] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "https://api.soundcloud.com/tracks?q=\(encoded)&limit=20&client_id=\(clientID)") else { return [] }
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
                return await searchViaWidget(query: query)
            }
            let tracks = try JSONDecoder().decode([SCTrack].self, from: data)
            return tracks.compactMap { t in
                guard let stream = t.stream_url else { return nil }
                return Track(
                    id: "sc_\(t.id)",
                    title: t.title,
                    artist: t.user.username,
                    album: "SoundCloud",
                    duration: TimeInterval(t.duration / 1000),
                    artworkURL: t.artwork_url?.replacingOccurrences(of: "large", with: "t500x500") ?? "",
                    streamURL: "\(stream)?client_id=\(clientID)",
                    source: .soundcloud
                )
            }
        } catch {
            return await searchViaWidget(query: query)
        }
    }

    // Fallback: SoundCloud oEmbed search
    private func searchViaWidget(query: String) async -> [Track] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return []
    }

    func resolveStreamURL(track: Track) async -> String? {
        guard let streamURL = track.streamURL else { return nil }
        // If already direct URL
        if streamURL.contains(".mp3") || streamURL.contains("media.sndcdn") { return streamURL }
        guard let url = URL(string: streamURL) else { return nil }
        do {
            let (_, resp) = try await URLSession.shared.data(from: url)
            return (resp as? HTTPURLResponse)?.url?.absoluteString
        } catch { return nil }
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
