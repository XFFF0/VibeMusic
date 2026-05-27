import Foundation

/// Extracts streamable audio URLs from YouTube videos.
/// Uses a server-side proxy (self-hosted or free public instance) to comply with
/// YouTube ToS — the IPA itself never calls yt-dlp directly.
class YouTubeAudioExtractor {
    static let shared = YouTubeAudioExtractor()

    // You can self-host: https://github.com/nickcoutsos/ytdl-server
    // Or use the Invidious / Piped API (open-source YouTube front-end)
    private let invidiousInstances = [
        "https://invidious.io.lol/api/v1",
        "https://invidious.fdn.fr/api/v1",
        "https://vid.puffyan.us/api/v1"
    ]

    func extractAudioURL(videoID: String, quality: AudioPlayerService.AudioQuality) async -> URL? {
        for instance in invidiousInstances {
            if let url = await fetchFromInvidious(instance: instance, videoID: videoID, quality: quality) {
                return url
            }
        }
        return nil
    }

    private func fetchFromInvidious(instance: String, videoID: String, quality: AudioPlayerService.AudioQuality) async -> URL? {
        guard let url = URL(string: "\(instance)/videos/\(videoID)?fields=adaptiveFormats,formatStreams") else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(InvidiousVideoResponse.self, from: data)

            // Prefer audio-only adaptive formats
            let audioFormats = response.adaptiveFormats
                .filter { $0.type.contains("audio") }
                .sorted { formatQuality($0, target: quality) > formatQuality($1, target: quality) }

            if let best = audioFormats.first, let streamURL = URL(string: best.url) {
                return streamURL
            }

            // Fallback to muxed stream
            if let muxed = response.formatStreams.first, let streamURL = URL(string: muxed.url) {
                return streamURL
            }
        } catch {}
        return nil
    }

    private func formatQuality(_ format: InvidiousVideoResponse.AudioFormat, target: AudioPlayerService.AudioQuality) -> Int {
        let bitrate = format.bitrate ?? 0
        switch target {
        case .ultra, .lossless: return bitrate
        case .high:             return abs(bitrate - 256000) < 50000 ? 1000 : bitrate / 1000
        case .standard:         return abs(bitrate - 128000) < 30000 ? 1000 : bitrate / 1000
        }
    }

    struct InvidiousVideoResponse: Codable {
        let adaptiveFormats: [AudioFormat]
        let formatStreams: [MuxedFormat]

        struct AudioFormat: Codable {
            let type: String
            let url: String
            let bitrate: Int?
            let audioQuality: String?
        }
        struct MuxedFormat: Codable {
            let url: String
            let qualityLabel: String?
        }
    }
}
