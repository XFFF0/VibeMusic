import Foundation

@MainActor
class DownloadService: ObservableObject {
    static let shared = DownloadService()
    @Published var active: [String: Double] = [:]   // trackID -> progress 0..1

    private init() {}

    func download(_ track: Track) async {
        guard active[track.id] == nil else { return }
        active[track.id] = 0

        var urlStr: String?
        if track.source == .youtube, let vid = track.videoID {
            urlStr = await YouTubeService.shared.extractAudioURL(videoID: vid)
        } else {
            urlStr = track.streamURL
        }
        guard let str = urlStr, let url = URL(string: str) else {
            active.removeValue(forKey: track.id); return
        }

        let dest = downloadsDir().appendingPathComponent("\(track.id).m4a")
        try? FileManager.default.removeItem(at: dest)

        do {
            let (tmpURL, _) = try await URLSession.shared.download(from: url)
            try FileManager.default.moveItem(at: tmpURL, to: dest)
            active.removeValue(forKey: track.id)
            LibraryService.shared.markDownloaded(track.id, path: dest.path)
        } catch {
            active.removeValue(forKey: track.id)
        }
    }

    func isDownloaded(_ id: String) -> Bool {
        FileManager.default.fileExists(atPath: downloadsDir().appendingPathComponent("\(id).m4a").path)
    }

    private func downloadsDir() -> URL {
        let d = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("downloads")
        try? FileManager.default.createDirectory(at: d, withIntermediateDirectories: true)
        return d
    }
}
