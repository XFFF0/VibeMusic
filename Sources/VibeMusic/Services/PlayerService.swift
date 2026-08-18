import Foundation
import UIKit
import AVFoundation
import MediaPlayer
import Combine

@MainActor
final class PlayerService: ObservableObject {
    static let shared = PlayerService()

    @Published var currentTrack: Track?
    @Published var isPlaying    = false
    @Published var progress: Double = 0
    @Published var currentTime: TimeInterval = 0
    @Published var duration:    TimeInterval = 0
    @Published var isLoading    = false
    @Published var queue: [Track] = []
    @Published var queueIndex   = 0
    @Published var isShuffle    = false
    @Published var repeatMode: RepeatMode = .none
    @Published var volume: Float = 1.0
    @Published var showPlayer   = false

    enum RepeatMode { case none, one, all }

    var player: AVPlayer?
    private var timeObserver: Any?
    private var endObserver: AnyCancellable?

    private init() { setupRemoteControls() }

    // MARK: - Public API
    func play(track: Track, queue: [Track] = []) {
        self.queue = queue.isEmpty ? [track] : queue
        self.queueIndex = self.queue.firstIndex(where: { $0.id == track.id }) ?? 0
        load(track)
    }

    func playPause() {
        guard currentTrack != nil else { return }
        if isPlaying { player?.pause() } else { player?.play() }
        isPlaying.toggle()
        updateNowPlaying()
    }

    func next() {
        guard !queue.isEmpty else { return }
        let idx = isShuffle ? Int.random(in: 0..<queue.count) : (queueIndex + 1) % queue.count
        queueIndex = idx
        load(queue[idx])
    }

    func previous() {
        if currentTime > 3 { seek(to: 0); return }
        let idx = max(queueIndex - 1, 0)
        queueIndex = idx
        load(queue[idx])
    }

    func seek(to progress: Double) {
        let t = CMTime(seconds: duration * progress, preferredTimescale: 600)
        player?.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func seekTime(_ time: TimeInterval) {
        let t = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setVolume(_ v: Float) {
        volume = v
        player?.volume = v
    }

    // MARK: - Load
    private func load(_ track: Track) {
        isLoading = true
        isPlaying = false
        currentTrack = track
        stopPlayer()
        LibraryService.shared.addRecent(track)

        // Capture only what we need - avoid capturing self in detached task
        let trackCopy = track
        let currentVolume = volume

        Task { @MainActor in
            let urlString = await Self.resolveURL(for: trackCopy)
            guard let str = urlString, let url = URL(string: str) else {
                self.isLoading = false
                return
            }
            let item = AVPlayerItem(url: url)
            self.player = AVPlayer(playerItem: item)
            self.player?.volume = currentVolume
            self.player?.play()
            self.isPlaying  = true
            self.isLoading  = false
            self.addTimeObserver()
            self.observeEnd()
            self.updateNowPlaying()
        }
    }

    // nonisolated static so Task can call without actor hop issues
    private nonisolated static func resolveURL(for track: Track) async -> String? {
        if track.isDownloaded, let path = track.localPath {
            return "file://\(path)"
        }
        switch track.source {
        case .youtube:
            guard let vid = track.videoID else { return nil }
            return await YouTubeService.shared.extractAudioURL(videoID: vid)
        case .soundcloud:
            return await SoundCloudService.shared.resolveStreamURL(track: track)
                ?? track.streamURL
        case .local:
            return track.streamURL
        }
    }

    private func stopPlayer() {
        if let obs = timeObserver { player?.removeTimeObserver(obs); timeObserver = nil }
        endObserver?.cancel(); endObserver = nil
        player?.pause(); player = nil
        progress = 0; currentTime = 0; duration = 0
    }

    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] t in
            guard let self, let item = self.player?.currentItem else { return }
            let d = item.duration.seconds
            guard d.isFinite, d > 0 else { return }
            self.duration    = d
            self.currentTime = t.seconds
            self.progress    = t.seconds / d
        }
    }

    private func observeEnd() {
        endObserver = NotificationCenter.default
            .publisher(for: .AVPlayerItemDidPlayToEndTime)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                switch self.repeatMode {
                case .one:  self.seek(to: 0); self.player?.play()
                case .all:  self.next()
                case .none: if self.queueIndex < self.queue.count - 1 { self.next() } else { self.isPlaying = false }
                }
            }
    }

    // MARK: - Lock Screen
    private func setupRemoteControls() {
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget           { [weak self] _ in Task { @MainActor in self?.playPause() };    return .success }
        c.pauseCommand.addTarget          { [weak self] _ in Task { @MainActor in self?.playPause() };    return .success }
        c.nextTrackCommand.addTarget      { [weak self] _ in Task { @MainActor in self?.next() };         return .success }
        c.previousTrackCommand.addTarget  { [weak self] _ in Task { @MainActor in self?.previous() };     return .success }
        c.changePlaybackPositionCommand.addTarget { [weak self] e in
            if let ev = e as? MPChangePlaybackPositionCommandEvent {
                Task { @MainActor in self?.seekTime(ev.positionTime) }
            }
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let t = currentTrack else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle:  t.title,
            MPMediaItemPropertyArtist: t.artist,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration:         duration,
            MPNowPlayingInfoPropertyPlaybackRate:        isPlaying ? 1.0 : 0.0
        ]
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        let artURLString = t.artworkURL
        Task { @MainActor in
            guard let artURL = URL(string: artURLString),
                  let data   = try? Data(contentsOf: artURL),
                  let image  = UIImage(data: data) else { return }
            let art = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            info[MPMediaItemPropertyArtwork] = art
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }
}
