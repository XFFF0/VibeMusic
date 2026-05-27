import Foundation

struct Track: Identifiable, Codable, Equatable {
    let id: String
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var thumbnailURL: String?
    var audioURL: String?
    var videoID: String?        // YouTube video ID
    var spotifyID: String?
    var source: Source
    var lyrics: String?
    var isDownloaded: Bool = false
    var localPath: String?
    var addedAt: Date = Date()

    enum Source: String, Codable {
        case youtube, youtubeMusic, spotify, local
        var displayName: String {
            switch self {
            case .youtube:      return "YouTube"
            case .youtubeMusic: return "YouTube Music"
            case .spotify:      return "Spotify"
            case .local:        return "Local"
            }
        }
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct SearchResult: Identifiable {
    let id: String
    let track: Track
    let relevanceScore: Double
}

struct Playlist: Identifiable, Codable {
    let id: String
    var name: String
    var description: String?
    var coverURL: String?
    var tracks: [Track]
    var createdAt: Date
    var updatedAt: Date
    var isPublic: Bool = false

    var trackCount: Int { tracks.count }
    var totalDuration: TimeInterval { tracks.reduce(0) { $0 + $1.duration } }
}
