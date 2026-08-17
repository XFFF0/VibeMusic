import Foundation

class LyricsService {
    static let shared = LyricsService()
    private init() {}

    func fetch(title: String, artist: String) async -> String? {
        let a = artist.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? artist
        let t = title.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? title
        guard let url = URL(string: "https://api.lyrics.ovh/v1/\(a)/\(t)") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            struct Resp: Codable { let lyrics: String? }
            return try JSONDecoder().decode(Resp.self, from: data).lyrics
        } catch { return nil }
    }
}
