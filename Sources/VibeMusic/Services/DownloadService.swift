import Foundation

class DownloadService: ObservableObject {
    static let shared = DownloadService()
    @Published var active: [String: Double] = [:]

    private init() {}

    func download(_ track: Track) {
        guard active[track.id] == nil else { return }
        active[track.id] = 0

        // Capture only value types - no self capture
        let trackID    = track.id
        let source     = track.source
        let videoID    = track.videoID
        let streamURL  = track.streamURL
        let isDownloaded = track.isDownloaded
        let localPath  = track.localPath

        Task.detached {
            var urlStr: String?
            if isDownloaded, let path = localPath {
                urlStr = "file://\(path)"
            } else if source == .youtube, let vid = videoID {
                urlStr = await YouTubeService.shared.extractAudioURL(videoID: vid)
            } else {
                urlStr = streamURL
            }

            guard let str = urlStr, let url = URL(string: str) else {
                await MainActor.run { DownloadService.shared.active.removeValue(forKey: trackID) }
                return
            }

            let dest = Self.downloadsDir().appendingPathComponent("\(trackID).m4a")
            try? FileManager.default.removeItem(at: dest)

            do {
                let (tmpURL, _) = try await URLSession.shared.download(from: url)
                try FileManager.default.moveItem(at: tmpURL, to: dest)
                await MainActor.run {
                    DownloadService.shared.active.removeValue(forKey: trackID)
                    LibraryService.shared.markDownloaded(trackID, path: dest.path)
                }
            } catch {
                await MainActor.run {
                    DownloadService.shared.active.removeValue(forKey: trackID)
                }
            }
        }
    }

    func isDownloaded(_ id: String) -> Bool {
        FileManager.default.fileExists(
            atPath: Self.downloadsDir().appendingPathComponent("\(id).m4a").path
        )
    }

    static func downloadsDir() -> URL {
        let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("downloads")
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
}
