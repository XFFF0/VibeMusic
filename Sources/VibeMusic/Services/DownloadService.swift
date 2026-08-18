import Foundation

class DownloadService: ObservableObject {
    static let shared = DownloadService()
    @Published var active: [String: Double] = [:]

    private init() {}

    // Not async - fire and forget
    func download(_ track: Track) {
        guard active[track.id] == nil else { return }
        active[track.id] = 0

        Task.detached { [weak self] in
            var urlStr: String?
            if track.source == .youtube, let vid = track.videoID {
                urlStr = await YouTubeService.shared.extractAudioURL(videoID: vid)
            } else {
                urlStr = track.streamURL
            }

            guard let str = urlStr, let url = URL(string: str) else {
                await MainActor.run { self?.active.removeValue(forKey: track.id) }
                return
            }

            let dest = Self.downloadsDir().appendingPathComponent("\(track.id).m4a")
            try? FileManager.default.removeItem(at: dest)

            do {
                let (tmpURL, _) = try await URLSession.shared.download(from: url)
                try FileManager.default.moveItem(at: tmpURL, to: dest)
                // Call @MainActor method on main actor
                await MainActor.run {
                    self?.active.removeValue(forKey: track.id)
                    Task { @MainActor in
                        LibraryService.shared.markDownloaded(track.id, path: dest.path)
                    }
                }
            } catch {
                await MainActor.run { self?.active.removeValue(forKey: track.id) }
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
