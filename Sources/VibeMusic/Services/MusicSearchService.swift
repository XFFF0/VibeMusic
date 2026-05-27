import Foundation
import Combine

class MusicSearchService: ObservableObject {
    static let shared = MusicSearchService()

    @Published var results: [Track] = []
    @Published var isSearching = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    // 💡 التعديل المصحح: قراءة المفتاح مباشرة من الـ main dictionary لضمان قراءته في الـ IPA
    private var youtubeAPIKey: String {
        return Bundle.main.infoDictionary?["YOUTUBE_API_KEY"] as? String ?? ""
    }
    private var rapidAPIKey: String {
        return Bundle.main.infoDictionary?["RAPID_API_KEY"] as? String ?? ""
    }

    func search(query: String, sources: [Track.Source] = [.youtubeMusic, .youtube, .spotify]) async {
        guard !query.isEmpty else { return }
        await MainActor.run { isSearching = true; results = [] }

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

        await MainActor.run { [allResults] in
            self.results = allResults
            self.isSearching = false
        }
    }

    // MARK: - YouTube Search
    private func searchYouTube(query: String) async -> [Track] {
        // التحقق من وجود المفتاح، وإذا كان فارغاً يتم الانتقال للمحاكاة الوهمية
        guard !youtubeAPIKey.isEmpty else { return mockYouTubeTracks(query: query) }

        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlStr = "https://www.googleapis.com/youtube/v3/search?part=snippet&q=\(encoded)+music&type=video&videoCategoryId=10&maxResults=15&key=\(youtubeAPIKey)"

        guard let url = URL(string: urlStr) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(YouTubeSearchResponse.self, from: data)
            return response.items.map { item in
                Track(
                    id: item.id.videoId,
                    title: item.snippet.title.decodedHTML,
                    artist: item.snippet.channelTitle,
                    album: "YouTube Music",
                    duration: 0,
                    thumbnailURL: item.snippet.thumbnails.high.url,
                    videoID: item.id.videoId,
                    source: .youtube
                )
            }
        } catch {
            // في حال فشل الاتصال بالإنترنت أو الخادم
            return mockYouTubeTracks(query: query)
        }
    }

    // MARK: - Spotify Search (via RapidAPI)
    private func searchSpotify(query: String) async -> [Track] {
        guard !rapidAPIKey.isEmpty else { return [] }

        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        guard let url = URL(string: "https://spotify23.p.rapidapi.com/search/?q=\(encoded)&type=tracks&offset=0&limit=10&numberOfTopResults=5") else { return [] }

        var request = URLRequest(url: url)
        request.setValue(rapidAPIKey, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("spotify23.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
            return response.tracks.items.map { item in
                Track(
                    id: item.data.id,
                    title: item.data.name,
                    artist: item.data.artists.items.first?.profile.name ?? "Unknown",
                    album: item.data.albumOfTrack.name,
                    duration: TimeInterval(item.data.duration.totalMilliseconds) / 1000,
                    thumbnailURL: item.data.albumOfTrack.coverArt.sources.first?.url,
                    spotifyID: item.data.id,
                    source: .spotify
                )
            }
        } catch {
            return []
        }
    }

    // MARK: - Mock data for testing without API keys
    private func mockYouTubeTracks(query: String) -> [Track] {
        let artists = ["The Weeknd", "Drake", "Taylor Swift", "Bad Bunny", "Dua Lipa"]
        return (0..<8).map { i in
            Track(
                id: "mock_\(i)_\(query.hashValue)",
                title: "\(query) - Track \(i+1)",
                artist: artists[i % artists.count],
                album: "Album \(i+1)",
                duration: TimeInterval(180 + i * 15),
                thumbnailURL: "https://picsum.photos/seed/\(i)/300/300",
                videoID: "dQw4w9WgXcQ",
                source: .youtube
            )
        }
    }
}
