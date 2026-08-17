import Foundation

class YouTubeService {
    static let shared = YouTubeService()

    // Uses Invidious open-source YouTube API - no key needed
    private let instances = [
        "https://invidious.io.lol",
        "https://invidious.fdn.fr",
        "https://inv.nadeko.net",
        "https://invidious.nerdvpn.de"
    ]

    func search(query: String) async -> [Track] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        for instance in instances {
            if let tracks = await searchInvidious(base: instance, query: encoded) {
                return tracks
            }
        }
        return []
    }

    private func searchInvidious(base: String, query: String) async -> [Track]? {
        guard let url = URL(string: "\(base)/api/v1/search?q=\(query)&type=video&page=1") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let results = try JSONDecoder().decode([InvidiousResult].self, from: data)
            return results.prefix(20).map { item in
                Track(
                    id: item.videoId,
                    title: item.title,
                    artist: item.author,
                    album: "YouTube",
                    duration: TimeInterval(item.lengthSeconds),
                    artworkURL: item.videoThumbnails.first?.url ?? "",
                    videoID: item.videoId,
                    source: .youtube
                )
            }
        } catch {
            return nil
        }
    }

    func extractAudioURL(videoID: String) async -> String? {
        for instance in instances {
            if let url = await extractFromInstance(base: instance, videoID: videoID) {
                return url
            }
        }
        return nil
    }

    private func extractFromInstance(base: String, videoID: String) async -> String? {
        guard let url = URL(string: "\(base)/api/v1/videos/\(videoID)?fields=adaptiveFormats,formatStreams") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let video = try JSONDecoder().decode(InvidiousVideo.self, from: data)

            // Best audio-only format
            let audioFmt = video.adaptiveFormats
                .filter { $0.type.contains("audio/mp4") || $0.type.contains("audio/webm") }
                .sorted { ($0.bitrate ?? 0) > ($1.bitrate ?? 0) }
                .first

            if let url = audioFmt?.url { return url }

            // Fallback: muxed stream
            return video.formatStreams.first?.url
        } catch {
            return nil
        }
    }

    // MARK: - Models
    struct InvidiousResult: Codable {
        let videoId: String
        let title: String
        let author: String
        let lengthSeconds: Int
        let videoThumbnails: [Thumbnail]
        struct Thumbnail: Codable { let quality: String; let url: String }
    }

    struct InvidiousVideo: Codable {
        let adaptiveFormats: [Format]
        let formatStreams: [MuxedFormat]
        struct Format: Codable {
            let type: String; let url: String; let bitrate: Int?
        }
        struct MuxedFormat: Codable { let url: String }
    }
}
