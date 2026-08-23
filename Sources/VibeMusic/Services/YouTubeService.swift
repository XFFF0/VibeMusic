import Foundation

class YouTubeService {
    static let shared = YouTubeService()
    private init() {}

    private var ytKey:     String { AppConfig.youtubeAPIKey }
    private var rapidKey:  String { AppConfig.rapidAPIKey }

    private let invidiousInstances = [
        "https://invidious.io.lol",
        "https://iv.ggtyler.dev",
        "https://invidious.privacydev.net",
        "https://yt.drgnz.club",
        "https://invidious.nerdvpn.de"
    ]
    private let pipedInstances = [
        "https://pipedapi.kavin.rocks",
        "https://pipedapi.adminforge.de",
        "https://pipedapi.tokhmi.xyz"
    ]

    // MARK: - Search (Official YouTube Data API v3)
    func search(query: String) async -> [Track] {
        if !ytKey.isEmpty {
            if let t = await searchOfficial(query: query), !t.isEmpty { return t }
        }
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        for base in invidiousInstances {
            if let t = await searchInvidious(base: base, query: q), !t.isEmpty { return t }
        }
        for base in pipedInstances {
            if let t = await searchPiped(base: base, query: q), !t.isEmpty { return t }
        }
        return []
    }

    private func searchOfficial(query: String) async -> [Track]? {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(q)&type=video&maxResults=20&key=\(ytKey)") else { return nil }
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let r = try JSONDecoder().decode(YTSearchResponse.self, from: data)
            return r.items.map { item in
                Track(
                    id: item.id.videoId,
                    title: item.snippet.title.htmlDecoded,
                    artist: item.snippet.channelTitle.htmlDecoded,
                    album: "YouTube", duration: 0,
                    artworkURL: item.snippet.thumbnails.high?.url ?? item.snippet.thumbnails.medium?.url ?? "",
                    videoID: item.id.videoId, source: .youtube
                )
            }
        } catch { return nil }
    }

    private func searchInvidious(base: String, query: String) async -> [Track]? {
        guard let url = URL(string: "\(base)/api/v1/search?q=\(query)&type=video") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 8)
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let items = try JSONDecoder().decode([InvResult].self, from: data)
            return items.prefix(20).map { v in
                let thumb = v.videoThumbnails.first(where: { $0.quality == "high" })?.url ?? v.videoThumbnails.first?.url ?? ""
                return Track(id: v.videoId, title: v.title, artist: v.author, album: "YouTube",
                    duration: TimeInterval(v.lengthSeconds),
                    artworkURL: thumb.hasPrefix("//") ? "https:" + thumb : thumb,
                    videoID: v.videoId, source: .youtube)
            }
        } catch { return nil }
    }

    private func searchPiped(base: String, query: String) async -> [Track]? {
        guard let url = URL(string: "\(base)/search?q=\(query)&filter=music_songs") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let r = try JSONDecoder().decode(PipedSearch.self, from: data)
            return r.items.prefix(20).compactMap { item in
                guard item.type == "stream", let vid = item.url?.components(separatedBy: "=").last else { return nil }
                return Track(id: vid, title: item.title ?? "", artist: item.uploaderName ?? "",
                    album: "YouTube", duration: TimeInterval(item.duration ?? 0),
                    artworkURL: item.thumbnail ?? "", videoID: vid, source: .youtube)
            }
        } catch { return nil }
    }

    // MARK: - Audio Extraction
    // Strategy: RapidAPI (most reliable) -> Invidious -> Piped
    func extractAudioURL(videoID: String) async -> String? {
        // 1. RapidAPI youtube-mp36 (free tier: 500 req/month)
        if !rapidKey.isEmpty {
            if let u = await extractRapidAPI(videoID: videoID) { return u }
        }
        // 2. Invidious instances
        for base in invidiousInstances {
            if let u = await extractInvidious(base: base, videoID: videoID) { return u }
        }
        // 3. Piped instances
        for base in pipedInstances {
            if let u = await extractPiped(base: base, videoID: videoID) { return u }
        }
        return nil
    }

    private func extractRapidAPI(videoID: String) async -> String? {
        guard let url = URL(string: "https://youtube-mp36.p.rapidapi.com/dl?id=\(videoID)") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.setValue(rapidKey, forHTTPHeaderField: "X-RapidAPI-Key")
        req.setValue("youtube-mp36.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            struct Resp: Codable { let link: String?; let status: String? }
            let r = try JSONDecoder().decode(Resp.self, from: data)
            return r.link
        } catch { return nil }
    }

    private func extractInvidious(base: String, videoID: String) async -> String? {
        guard let url = URL(string: "\(base)/api/v1/videos/\(videoID)?fields=adaptiveFormats,formatStreams") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 10)
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let v = try JSONDecoder().decode(InvVideo.self, from: data)
            return v.adaptiveFormats
                .filter { $0.type.contains("audio/mp4") || $0.type.contains("audio/webm") }
                .sorted { ($0.bitrate ?? 0) > ($1.bitrate ?? 0) }
                .first?.url ?? v.formatStreams.first?.url
        } catch { return nil }
    }

    private func extractPiped(base: String, videoID: String) async -> String? {
        guard let url = URL(string: "\(base)/streams/\(videoID)") else { return nil }
        var req = URLRequest(url: url, timeoutInterval: 10)
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let s = try JSONDecoder().decode(PipedStreams.self, from: data)
            return s.audioStreams.sorted { ($0.bitrate ?? 0) > ($1.bitrate ?? 0) }.first?.url
        } catch { return nil }
    }

    // MARK: - Models
    struct YTSearchResponse: Codable {
        let items: [Item]
        struct Item: Codable {
            let id: VideoID; let snippet: Snippet
            struct VideoID: Codable { let videoId: String }
            struct Snippet: Codable {
                let title: String; let channelTitle: String; let thumbnails: Thumbs
                struct Thumbs: Codable {
                    let `default`: Thumb?; let medium: Thumb?; let high: Thumb?
                    struct Thumb: Codable { let url: String }
                }
            }
        }
    }
    struct InvResult: Codable {
        let videoId: String; let title: String; let author: String; let lengthSeconds: Int
        let videoThumbnails: [Thumb]
        struct Thumb: Codable { let quality: String; let url: String }
    }
    struct InvVideo: Codable {
        let adaptiveFormats: [Fmt]; let formatStreams: [Mux]
        struct Fmt: Codable { let type: String; let url: String; let bitrate: Int? }
        struct Mux: Codable { let url: String }
    }
    struct PipedSearch: Codable {
        let items: [Item]
        struct Item: Codable {
            let type: String?; let url: String?; let title: String?
            let uploaderName: String?; let thumbnail: String?; let duration: Int?
        }
    }
    struct PipedStreams: Codable {
        let audioStreams: [AS]
        struct AS: Codable { let url: String; let bitrate: Int? }
    }
}

extension String {
    var htmlDecoded: String {
        var s = self
        [("&amp;","&"),("&lt;","<"),("&gt;",">"),("&quot;","\""),("&#39;","'")].forEach {
            s = s.replacingOccurrences(of: $0.0, with: $0.1)
        }
        return s
    }
}
