import Foundation

class YouTubeService {
    static let shared = YouTubeService()
    private init() {}

    // Multiple Invidious instances - app tries each until one responds
    private let invidiousInstances = [
        "https://invidious.io.lol",
        "https://iv.ggtyler.dev",
        "https://invidious.privacydev.net",
        "https://invidious.nerdvpn.de",
        "https://yt.drgnz.club",
        "https://invidious.perennialte.ch"
    ]

    // Piped API instances (alternative open YouTube frontend)
    private let pipedInstances = [
        "https://pipedapi.kavin.rocks",
        "https://pipedapi.adminforge.de",
        "https://pipedapi.tokhmi.xyz"
    ]

    // MARK: - Search
    func search(query: String) async -> [Track] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query

        // Try Invidious first
        for instance in invidiousInstances {
            if let tracks = await searchInvidious(base: instance, query: encoded) {
                return tracks
            }
        }

        // Fallback: Piped API
        for instance in pipedInstances {
            if let tracks = await searchPiped(base: instance, query: encoded) {
                return tracks
            }
        }

        return []
    }

    private func searchInvidious(base: String, query: String) async -> [Track]? {
        guard let url = URL(string: "\(base)/api/v1/search?q=\(query)&type=video&page=1") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 6)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let results = try JSONDecoder().decode([InvidiousResult].self, from: data)
            return results.prefix(20).map { item in
                let thumb = item.videoThumbnails.first(where: { $0.quality == "high" })?.url
                    ?? item.videoThumbnails.first?.url ?? ""
                return Track(
                    id: item.videoId,
                    title: item.title,
                    artist: item.author,
                    album: "YouTube",
                    duration: TimeInterval(item.lengthSeconds),
                    artworkURL: thumb.hasPrefix("//") ? "https:" + thumb : thumb,
                    videoID: item.videoId,
                    source: .youtube
                )
            }
        } catch { return nil }
    }

    private func searchPiped(base: String, query: String) async -> [Track]? {
        guard let url = URL(string: "\(base)/search?q=\(query)&filter=music_songs") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 6)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let response = try JSONDecoder().decode(PipedSearchResponse.self, from: data)
            return response.items.prefix(20).compactMap { item in
                guard item.type == "stream", let vid = item.url?.components(separatedBy: "=").last else { return nil }
                let thumb = item.thumbnail ?? ""
                return Track(
                    id: vid,
                    title: item.title ?? "Unknown",
                    artist: item.uploaderName ?? "Unknown",
                    album: "YouTube",
                    duration: TimeInterval(item.duration ?? 0),
                    artworkURL: thumb,
                    videoID: vid,
                    source: .youtube
                )
            }
        } catch { return nil }
    }

    // MARK: - Audio extraction
    func extractAudioURL(videoID: String) async -> String? {
        // Try Invidious
        for instance in invidiousInstances {
            if let url = await extractInvidious(base: instance, videoID: videoID) {
                return url
            }
        }
        // Try Piped
        for instance in pipedInstances {
            if let url = await extractPiped(base: instance, videoID: videoID) {
                return url
            }
        }
        return nil
    }

    private func extractInvidious(base: String, videoID: String) async -> String? {
        guard let url = URL(string: "\(base)/api/v1/videos/\(videoID)?fields=adaptiveFormats,formatStreams") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 8)
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let video = try JSONDecoder().decode(InvidiousVideo.self, from: data)
            // Best audio format
            let audioURL = video.adaptiveFormats
                .filter { $0.type.contains("audio/mp4") || $0.type.contains("audio/webm") }
                .sorted { ($0.bitrate ?? 0) > ($1.bitrate ?? 0) }
                .first?.url
            return audioURL ?? video.formatStreams.first?.url
        } catch { return nil }
    }

    private func extractPiped(base: String, videoID: String) async -> String? {
        guard let url = URL(string: "\(base)/streams/\(videoID)") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let response = try JSONDecoder().decode(PipedStreams.self, from: data)
            // Best audio stream
            return response.audioStreams
                .sorted { ($0.bitrate ?? 0) > ($1.bitrate ?? 0) }
                .first?.url
        } catch { return nil }
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
        let adaptiveFormats: [AudioFormat]
        let formatStreams: [MuxedFormat]
        struct AudioFormat: Codable { let type: String; let url: String; let bitrate: Int? }
        struct MuxedFormat: Codable { let url: String }
    }

    struct PipedSearchResponse: Codable {
        let items: [PipedItem]
        struct PipedItem: Codable {
            let type: String?
            let url: String?
            let title: String?
            let uploaderName: String?
            let thumbnail: String?
            let duration: Int?
        }
    }

    struct PipedStreams: Codable {
        let audioStreams: [AudioStream]
        struct AudioStream: Codable { let url: String; let bitrate: Int? }
    }
}
