import Foundation
import AVFoundation
import MediaPlayer
import Combine

@MainActor
class PlayerService: ObservableObject {
    static let shared = PlayerService()

    @Published var currentTrack: Track?
    @Published var isPlaying = false
    @Published var progress: Double = 0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading = false
    @Published var queue: [Track] = []
    @Published var queueIndex = 0
    @Published var isShuffle = false
    @Published var repeatMode: RepeatMode = .none
    @Published var volume: Float = 1.0
    @Published var showPlayer = false

    enum RepeatMode { case none, one, all }

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var shuffleOrder: [Int] = []

    private init() { setupRemoteControls() }

    // MARK: - Play
    func play(track: Track, queue: [Track] = []) {
        self.queue = queue.isEmpty ? [track] : queue
        self.queueIndex = queue.firstIndex(where: { $0.id == track.id }) ?? 0
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
        switch repeatMode {
        case .one:
            seek(to: 0); player?.play(); isPlaying = true
        default:
            let next = isShuffle
                ? Int.random(in: 0..<queue.count)
                : (queueIndex + 1) % queue.count
            queueIndex = next
            load(queue[next])
        }
    }

    func previous() {
        if currentTime > 3 { seek(to: 0); return }
        let prev = max(queueIndex - 1, 0)
        queueIndex = prev
        load(queue[prev])
    }

    func seek(to progress: Double) {
        let t = CMTime(seconds: duration * progress, preferredTimescale: 600)
        player?.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func seekTime(_ time: TimeInterval) {
        let t = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    // MARK: - Load
    private func load(_ track: Track) {
        isLoading = true
        isPlaying = false
        currentTrack = track
        removeObserver()
        LibraryService.shared.addRecent(track)

        Task {
            var urlString: String?

            if track.isDownloaded, let path = track.localPath {
                urlString = "file://\(path)"
            } else if track.source == .youtube, let vid = track.videoID {
                urlString = await YouTubeService.shared.extractAudioURL(videoID: vid)
            } else if track.source == .soundcloud {
                urlString = await SoundCloudService.shared.resolveStreamURL(track: track)
                    ?? track.streamURL
            } else {
                urlString = track.streamURL
            }

            guard let str = urlString, let url = URL(string: str) else {
                await MainActor.run { isLoading = false }
                return
            }

            let item = AVPlayerItem(url: url)
            player = AVPlayer(playerItem: item)
            player?.volume = volume
            player?.play()
            isPlaying = true
            isLoading = false
            addObserver()
            updateNowPlaying()
            observeEnd()
        }
    }

    // MARK: - Observers
    private func addObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] t in
            guard let self, let item = self.player?.currentItem else { return }
            let d = item.duration.seconds
            guard d.isFinite, d > 0 else { return }
            self.duration = d
            self.currentTime = t.seconds
            self.progress = t.seconds / d
        }
    }

    private func removeObserver() {
        if let obs = timeObserver { player?.removeTimeObserver(obs); timeObserver = nil }
        player?.pause()
        cancellables.removeAll()
    }

    private func observeEnd() {
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                switch self.repeatMode {
                case .one:  self.seek(to: 0); self.player?.play()
                case .all:  self.next()
                case .none: if self.queueIndex < self.queue.count - 1 { self.next() } else { self.isPlaying = false }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Lock Screen
    private func setupRemoteControls() {
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget  { [weak self] _ in self?.playPause(); return .success }
        c.pauseCommand.addTarget { [weak self] _ in self?.playPause(); return .success }
        c.nextTrackCommand.addTarget { [weak self] _ in self?.next(); return .success }
        c.previousTrackCommand.addTarget { [weak self] _ in self?.previous(); return .success }
        c.changePlaybackPositionCommand.addTarget { [weak self] e in
            if let ev = e as? MPChangePlaybackPositionCommandEvent {
                self?.seekTime(ev.positionTime)
            }
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let t = currentTrack else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle:                t.title,
            MPMediaItemPropertyArtist:               t.artist,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration:     duration,
            MPNowPlayingInfoPropertyPlaybackRate:    isPlaying ? 1.0 : 0.0
        ]
        if let artURL = URL(string: t.artworkURL) {
            Task {
                if let data = try? Data(contentsOf: artURL), let img = UIImage(data: data) {
                    info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                }
            }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
