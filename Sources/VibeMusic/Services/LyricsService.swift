import Foundation

class LyricsService {
    static let shared = LyricsService()
    private let rapidAPIKey = Bundle.main.object(forInfoDictionaryKey: "RAPID_API_KEY") as? String ?? ""

    func fetchLyrics(title: String, artist: String) async -> String? {
        // Try Lyrics.ovh (free, no key needed)
        if let lyrics = await fetchFromLyricsOVH(title: title, artist: artist) { return lyrics }
        // Fallback: RapidAPI Genius
        if let lyrics = await fetchFromGenius(title: title, artist: artist) { return lyrics }
        return nil
    }

    private func fetchFromLyricsOVH(title: String, artist: String) async -> String? {
        let artistEncoded = artist.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? artist
        let titleEncoded  = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
        guard let url = URL(string: "https://api.lyrics.ovh/v1/\(artistEncoded)/\(titleEncoded)") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(LyricsOVHResponse.self, from: data)
            return response.lyrics
        } catch { return nil }
    }

    private func fetchFromGenius(title: String, artist: String) async -> String? {
        guard !rapidAPIKey.isEmpty else { return nil }
        let q = "\(artist) \(title)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://genius-song-lyrics1.p.rapidapi.com/search?q=\(q)&per_page=1&page=1") else { return nil }
        var req = URLRequest(url: url)
        req.setValue(rapidAPIKey, forHTTPHeaderField: "X-RapidAPI-Key")
        req.setValue("genius-song-lyrics1.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let resp = try JSONDecoder().decode(GeniusSearchResponse.self, from: data)
            if let hit = resp.response.hits.first {
                return await fetchGeniusLyricsPage(url: hit.result.url)
            }
        } catch {}
        return nil
    }

    private func fetchGeniusLyricsPage(url: String) async -> String? {
        // In a real app, scrape the Genius page or use their API for full lyrics
        return nil
    }

    struct LyricsOVHResponse: Codable { let lyrics: String? }
    struct GeniusSearchResponse: Codable {
        let response: Response
        struct Response: Codable {
            let hits: [Hit]
            struct Hit: Codable {
                let result: Result
                struct Result: Codable { let url: String; let title: String }
            }
        }
    }
}
