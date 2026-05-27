
import Foundation
import Combine

class MusicSearchService: ObservableObject {
    static let shared = MusicSearchService()

    @Published var results: [Track] = []
    @Published var isSearching = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private var currentSearchID: UUID = UUID()

    private var youtubeAPIKey: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: "YOUTUBE_API_KEY") as? String, !key.isEmpty {
            return key
        }
        return ProcessInfo.processInfo.environment["YOUTUBE_API_KEY"] ?? ""
    }

    private var rapidAPIKey: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: "RAPID_API_KEY") as? String, !key.isEmpty {
            return key
        }
        return ProcessInfo.processInfo.environment["RAPID_API_KEY"] ?? ""
    }

    func search(query: String, sources: [Track.Source] = [.youtubeMusic, .youtube, .spotify]) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let searchID = UUID()
        self.currentSearchID = searchID

        await MainActor.run {
            isSearching = true
            errorMessage = nil
            results = []
        }

        var allResults: [Track] = []

        await withTaskGroup(of: [Track].self) { group in
            if sources.contains(.youtubeMusic) || sources.contains(.youtube) {
                group.addTask { await self.searchYouTube(query: query) }
            }
            if sources.contains(.spotify) {
                group.addTask { await self.searchSpotify(query: query) }
            }
            for await tracks in group {
                allResults.append(contentsOf: tracks)
            }
        }

        await MainActor.run { [allResults, searchID] in
            guard self.currentSearchID == searchID else { return }
            self.results = allResults
            self.isSearching = false
            if allResults.isEmpty {
                self.errorMessage = "No results found"
            }
        }
    }

    // MARK: - YouTube Search
    private func searchYouTube(query: String) async -> [Track] {
        guard !youtubeAPIKey.isEmpty else {
            print("[Vibe] YOUTUBE_API_KEY is empty — using mock data")
            return mockYouTubeTracks(query: query)
        }

        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlStr = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(encoded)+music&type=video&videoCategoryId=10&maxResults=20&key=\(youtubeAPIKey)"

        guard let url = URL(string: urlStr) else {
            print("[Vibe] Invalid YouTube URL")
            return []
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse else { return [] }

            if http.statusCode != 200 {
                let body = String(data: data, encoding: .utf8) ?? "nil"
                print("[Vibe] YouTube API returned \(http.statusCode): \(body.prefix(300))")
                return mockYouTubeTracks(query: query)
            }

            let response = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
            print("[Vibe] YouTube returned \(response.items.count) results")

            return response.items.compactMap { item -> Track? in
                guard let videoId = item.id.videoId else { return nil }
                guard let thumbURL = item.snippet.thumbnails.high?.url ?? item.snippet.thumbnails.medium?.url ?? item.snippet.thumbnails.default?.url else { return nil }
                return Track(
                    id: videoId,
                    title: item.snippet.title.decodedHTML,
                    artist: item.snippet.channelTitle.decodedHTML,
                    album: "YouTube Music",
                    duration: 0,
                    thumbnailURL: thumbURL,
                    videoID: videoId,
                    source: .youtube
                )
            }
        } catch {
            print("[Vibe] YouTube decode error: \(error)")
            return mockYouTubeTracks(query: query)
        }
    }

    // MARK: - Spotify Search (via RapidAPI)
    private func searchSpotify(query: String) async -> [Track] {
        guard !rapidAPIKey.isEmpty else {
            print("[Vibe] RAPID_API_KEY is empty — skipping Spotify")
            return []
        }

        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "https://spotify23.p.rapidapi.com/search/?q=\(encoded)&type=tracks&offset=0&limit=10&numberOfTopResults=5") else { return [] }

        var request = URLRequest(url: url)
        request.setValue(rapidAPIKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("spotify23.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                print("[Vibe] Spotify API error: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                return []
            }
            let response = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
            print("[Vibe] Spotify returned \(response.tracks.items.count) results")

            return response.tracks.items.compactMap { item -> Track? in
                let artistName = item.data.artists.items.first?.profile.name ?? "Unknown"
                let coverURL = item.data.albumOfTrack.coverArt.sources.first?.url
                return Track(
                    id: "sp_\(item.data.id)",
                    title: item.data.name,
                    artist: artistName,
                    album: item.data.albumOfTrack.name,
                    duration: TimeInterval(item.data.duration.totalMilliseconds) / 1000.0,
                    thumbnailURL: coverURL,
                    spotifyID: item.data.id,
                    source: .spotify
                )
            }
        } catch {
            print("[Vibe] Spotify decode error: \(error)")
            return []
        }
    }

    // MARK: - Mock data
    private func mockYouTubeTracks(query: String) -> [Track] {
        print("[Vibe] Returning mock data for: \(query)")
        let artists = ["The Weeknd", "Drake", "Taylor Swift", "Bad Bunny", "Dua Lipa", "Ed Sheeran", "BTS", "Ariana Grande"]
        return (0..<8).map { i in
            Track(
                id: "mock_\(i)_\(abs(query.hashValue))",
                title: "\(query) — Track \(i + 1)",
                artist: artists[i % artists.count],
                album: "Top Hits \(2024 + i % 3)",
                duration: TimeInterval(180 + i * 17),
                thumbnailURL: "https://picsum.photos/seed/vibe\(i)\(abs(query.hashValue))/300/300",
                videoID: "dQw4w9WgXcQ",
                source: .youtube
            )
        }
    }
}

// MARK: - YouTube API Response Types
struct YouTubeSearchResponse: Codable {
    let items: [YouTubeSearchItem]
}

struct YouTubeSearchItem: Codable {
    let id: YouTubeSearchID
    let snippet: YouTubeSearchSnippet
}

struct YouTubeSearchID: Codable {
    let kind: String
    let videoId: String?
}

struct YouTubeSearchSnippet: Codable {
    let title: String
    let channelTitle: String
    let thumbnails: YouTubeThumbnails
}

struct YouTubeThumbnails: Codable {
    let `default`: YouTubeThumbnailSize?
    let medium: YouTubeThumbnailSize?
    let high: YouTubeThumbnailSize?
}

struct YouTubeThumbnailSize: Codable {
    let url: String
    let width: Int?
    let height: Int?
}

// MARK: - Spotify API Response Types
struct SpotifySearchResponse: Codable {
    let tracks: SpotifyTracksWrapper
}

struct SpotifyTracksWrapper: Codable {
    let items: [SpotifyTrackItem]
}

struct SpotifyTrackItem: Codable {
    let data: SpotifyTrackData
}

struct SpotifyTrackData: Codable {
    let id: String
    let name: String
    let duration: SpotifyDuration
    let artists: SpotifyArtistsWrapper
    let albumOfTrack: SpotifyAlbumWrapper
}

struct SpotifyDuration: Codable {
    let totalMilliseconds: Int
}

struct SpotifyArtistsWrapper: Codable {
    let items: [SpotifyArtistItem]
}

struct SpotifyArtistItem: Codable {
    let profile: SpotifyArtistProfile
}

struct SpotifyArtistProfile: Codable {
    let name: String
}

struct SpotifyAlbumWrapper: Codable {
    let name: String
    let coverArt: SpotifyCoverArt
}

struct SpotifyCoverArt: Codable {
    let sources: [SpotifyImageSource]
}

struct SpotifyImageSource: Codable {
    let url: String
    let width: Int?
    let height: Int?
}
