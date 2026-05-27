import Foundation
import Combine

@MainActor
class DownloadService: ObservableObject {
    static let shared = DownloadService()

    @Published var downloads: [String: DownloadTask] = [:]

    struct DownloadTask: Identifiable {
        let id: String
        var track: Track
        var progress: Double = 0
        var state: State = .waiting
        enum State { case waiting, downloading, done, failed }
    }

    private var urlSession: URLSession!

    private init() {
        let config = URLSessionConfiguration.background(withIdentifier: "com.vibe.music.download")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        urlSession = URLSession(configuration: config, delegate: nil, delegateQueue: .main)
    }

    func download(track: Track, quality: AudioPlayerService.AudioQuality = .high) async {
        guard downloads[track.id] == nil else { return }
        downloads[track.id] = DownloadTask(id: track.id, track: track, state: .waiting)

        guard let audioURL = await YouTubeAudioExtractor.shared.extractAudioURL(videoID: track.videoID ?? "", quality: quality) else {
            downloads[track.id]?.state = .failed
            return
        }

        downloads[track.id]?.state = .downloading

        do {
            let (localURL, _) = try await urlSession.download(from: audioURL)
            let saved = self.saveFile(from: localURL, for: track)
            self.downloads[track.id]?.state = saved != nil ? .done : .failed
            if let path = saved {
                LibraryService.shared.markDownloaded(trackID: track.id, localPath: path)
            }
        } catch {
            self.downloads[track.id]?.state = .failed
        }
    }

    func cancelDownload(trackID: String) {
        downloads.removeValue(forKey: trackID)
    }

    func isDownloaded(trackID: String) -> Bool {
        guard let path = LibraryService.shared.localPath(for: trackID) else { return false }
        return FileManager.default.fileExists(atPath: path)
    }

    private func saveFile(from tempURL: URL, for track: Track) -> String? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dest = docs.appendingPathComponent("downloads/\(track.id).m4a")
        try? FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.moveItem(at: tempURL, to: dest)
            return dest.path
        } catch { return nil }
    }

    var totalStorageUsed: Int64 {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let downloadsDir = docs.appendingPathComponent("downloads")
        guard let files = try? FileManager.default.contentsOfDirectory(at: downloadsDir, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        return files.reduce(0) { sum, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return sum + Int64(size)
        }
    }
}
