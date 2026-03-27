import AVFoundation
import Combine
import MediaPlayer

@Observable
class AudioStreamManager {
    static let shared = AudioStreamManager()

    var isPlaying = false
    var currentStation: RadioStation?
    var isBuffering = false
    var error: String?

    /// Read-only access for StreamLatencyEstimator to measure buffer depth.
    var currentPlayerItem: AVPlayerItem? { playerItem }

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var statusObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?

    private init() {}

    func play(station: RadioStation) {
        stop()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, policy: .longFormAudio)
            try session.setActive(true)
        } catch {
            self.error = "Audio session error: \(error.localizedDescription)"
            return
        }

        guard let url = URL(string: station.streamURL) else {
            self.error = "Invalid stream URL"
            return
        }

        isBuffering = true
        self.error = nil
        currentStation = station

        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        // Observe player item status
        statusObservation = playerItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    self?.isBuffering = false
                case .failed:
                    self?.isBuffering = false
                    self?.error = item.error?.localizedDescription ?? "Stream failed"
                default:
                    break
                }
            }
        }

        // Observe time control status for play/pause state
        timeControlObservation = player?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            DispatchQueue.main.async {
                switch player.timeControlStatus {
                case .playing:
                    self?.isPlaying = true
                    self?.isBuffering = false
                case .waitingToPlayAtSpecifiedRate:
                    self?.isBuffering = true
                case .paused:
                    self?.isPlaying = false
                @unknown default:
                    break
                }
            }
        }

        player?.play()
        updateNowPlayingInfo(station: station)
        setupRemoteCommandCenter()
    }

    func stop() {
        player?.pause()
        statusObservation?.invalidate()
        timeControlObservation?.invalidate()
        statusObservation = nil
        timeControlObservation = nil
        player = nil
        playerItem = nil
        isPlaying = false
        isBuffering = false
        currentStation = nil
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }

    private func updateNowPlayingInfo(station: RadioStation) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = station.displayName
        info[MPMediaItemPropertyArtist] = station.tagline
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func setupRemoteCommandCenter() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.removeTarget(nil)
        center.pauseCommand.removeTarget(nil)
        center.togglePlayPauseCommand.removeTarget(nil)

        center.playCommand.addTarget { [weak self] _ in
            self?.player?.play()
            return .success
        }

        center.pauseCommand.addTarget { [weak self] _ in
            self?.player?.pause()
            return .success
        }

        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        // Disable unsupported commands
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
        center.skipForwardCommand.isEnabled = false
        center.skipBackwardCommand.isEnabled = false
    }
}
