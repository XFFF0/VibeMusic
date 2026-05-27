import Foundation
import AVFoundation
import MediaPlayer
import Combine

@MainActor
class AudioPlayerService: ObservableObject {
    static let shared = AudioPlayerService()

    @Published var currentTrack: Track?
    @Published var isPlaying = false
    @Published var progress: Double = 0          // 0.0 – 1.0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 1.0
    @Published var isShuffled = false
    @Published var repeatMode: RepeatMode = .none
    @Published var queue: [Track] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading = false
    @Published var showFullPlayer = false
    @Published var quality: AudioQuality = .high

    enum RepeatMode { case none, one, all }
    enum AudioQuality: String, CaseIterable {
        case standard = "Standard (128kbps)"
        case high     = "High (256kbps)"
        case ultra    = "Ultra (320kbps)"
        case lossless = "Lossless (FLAC)"
    }

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupAudioSession()
        setupRemoteControls()
    }

    // MARK: - Playback Control
    func play(track: Track, queue: [Track] = []) {
        self.queue = queue.isEmpty ? [track] : queue
        self.currentIndex = queue.firstIndex(where: { $0.id == track.id }) ?? 0
        loadTrack(track)
    }

    func playPause() {
        if isPlaying { player?.pause() } else { player?.play() }
        isPlaying.toggle()
        updateNowPlaying()
    }

    func seek(to progress: Double) {
        let time = CMTime(seconds: duration * progress, preferredTimescale: 1000)
        player?.seek(to: time)
    }

    func skipNext() {
        guard !queue.isEmpty else { return }
        let nextIndex = isShuffled
            ? Int.random(in: 0..<queue.count)
            : (currentIndex + 1) % queue.count
        currentIndex = nextIndex
        loadTrack(queue[nextIndex])
    }

    func skipPrevious() {
        if currentTime > 3 { seek(to: 0); return }
        let prevIndex = max(currentIndex - 1, 0)
        currentIndex = prevIndex
        loadTrack(queue[prevIndex])
    }

    func setVolume(_ value: Float) {
        volume = value
        player?.volume = value
    }

    // MARK: - Internal
    private func loadTrack(_ track: Track) {
        isLoading = true
        currentTrack = track
        removeTimeObserver()

        Task {
            var url: URL?

            if track.isDownloaded, let localPath = track.localPath {
                url = URL(fileURLWithPath: localPath)
            } else if let videoID = track.videoID {
                url = await YouTubeAudioExtractor.shared.extractAudioURL(videoID: videoID, quality: quality)
            } else if let audioURL = track.audioURL, let u = URL(string: audioURL) {
                url = u
            }

            guard let audioURL = url else {
                isLoading = false
                return
            }

            let item = AVPlayerItem(url: audioURL)
            player = AVPlayer(playerItem: item)
            player?.volume = volume
            player?.play()
            isPlaying = true
            isLoading = false

            setupTimeObserver()
            updateNowPlaying()
            observePlaybackEnd()
        }
    }

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self, let item = self.player?.currentItem else { return }
            let dur = item.duration.seconds
            if dur.isFinite && dur > 0 {
                self.duration = dur
                self.currentTime = time.seconds
                self.progress = time.seconds / dur
            }
        }
    }

    private func removeTimeObserver() {
        if let obs = timeObserver { player?.removeTimeObserver(obs); timeObserver = nil }
    }

    private func observePlaybackEnd() {
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] _ in
                guard let self else { return }
                switch self.repeatMode {
                case .one:  self.seek(to: 0); self.player?.play()
                case .all:  self.skipNext()
                case .none: if self.currentIndex < self.queue.count - 1 { self.skipNext() } else { self.isPlaying = false }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Audio Session
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { print("Audio session error: \(error)") }
    }

    // MARK: - Remote Controls
    private func setupRemoteControls() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget  { [weak self] _ in self?.playPause(); return .success }
        center.pauseCommand.addTarget { [weak self] _ in self?.playPause(); return .success }
        center.nextTrackCommand.addTarget { [weak self] _ in self?.skipNext(); return .success }
        center.previousTrackCommand.addTarget { [weak self] _ in self?.skipPrevious(); return .success }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let e = event as? MPChangePlaybackPositionCommandEvent {
                self?.player?.seek(to: CMTime(seconds: e.positionTime, preferredTimescale: 1000))
            }
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let track = currentTrack else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle:       track.title,
            MPMediaItemPropertyArtist:      track.artist,
            MPMediaItemPropertyAlbumTitle:  track.album,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration:         duration,
            MPNowPlayingInfoPropertyPlaybackRate:        isPlaying ? 1.0 : 0.0
        ]
        if let thumbURL = track.thumbnailURL, let url = URL(string: thumbURL) {
            Task {
                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                }
            }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
