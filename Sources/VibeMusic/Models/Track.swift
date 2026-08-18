import Foundation

struct Track: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var artworkURL: String
    var streamURL: String?
    var videoID: String?
    var source: Source
    var isDownloaded: Bool = false
    var localPath: String?
    var addedAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case id, title, artist, album, duration, artworkURL, streamURL, videoID, source, isDownloaded, localPath, addedAt
    }

    enum Source: String, Codable, CaseIterable {
        case youtube     = "YouTube"
        case soundcloud  = "SoundCloud"
        case local       = "Local"

        var icon: String {
            switch self {
            case .youtube:    return "play.rectangle.fill"
            case .soundcloud: return "cloud.fill"
            case .local:      return "internaldrive.fill"
            }
        }
        var color: String {
            switch self {
            case .youtube:    return "red"
            case .soundcloud: return "orange"
            case .local:      return "green"
            }
        }
    }

    var formattedDuration: String {
        guard duration > 0 else { return "--:--" }
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
    }
}

struct Playlist: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var description: String = ""
    var tracks: [Track] = []
    var createdAt: Date = Date()

    var totalDuration: TimeInterval { tracks.reduce(0) { $0 + $1.duration } }
    var formattedDuration: String {
        let total = Int(totalDuration)
        let h = total / 3600
        let m = (total % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m) min"
    }
}
