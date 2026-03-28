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
    private var shouldResumeAfterInterruption = false
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 5
    private var reconnectTask: Task<Void, Never>?

    private init() {
        setupInterruptionHandling()
    }

    // MARK: - Audio Interruption Handling

    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }

        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        switch type {
        case .began:
            shouldResumeAfterInterruption = isPlaying
            player?.pause()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) && shouldResumeAfterInterruption {
                player?.play()
            }
            shouldResumeAfterInterruption = false
        @unknown default:
            break
        }
    }

    private func attemptReconnect() {
        guard let station = currentStation, reconnectAttempts < maxReconnectAttempts else {
            error = "Stream failed after \(reconnectAttempts) retries"
            AppLogger.audio.error("Stream failed permanently after \(self.reconnectAttempts) attempts")
            return
        }
        reconnectAttempts += 1
        let delay = TimeInterval(pow(2.0, Double(reconnectAttempts)))
        AppLogger.audio.info("Reconnecting in \(delay)s (attempt \(self.reconnectAttempts)/\(self.maxReconnectAttempts))")
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self, let station = self.currentStation else { return }
            await MainActor.run {
                self.playStream(station: station)
            }
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .oldDeviceUnavailable {
            player?.pause()
        }
    }

    func play(station: RadioStation) {
        reconnectTask?.cancel()
        reconnectTask = nil
        reconnectAttempts = 0
        stop()
        playStream(station: station)
    }

    /// Internal stream setup — used by both `play` and reconnect.
    private func playStream(station: RadioStation) {
        // Tear down existing player without full stop() (preserves reconnect state)
        player?.pause()
        statusObservation?.invalidate()
        timeControlObservation?.invalidate()
        player = nil
        playerItem = nil

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
                    self?.reconnectAttempts = 0
                case .failed:
                    self?.isBuffering = false
                    self?.attemptReconnect()
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
        shouldResumeAfterInterruption = false
        reconnectTask?.cancel()
        reconnectTask = nil
        reconnectAttempts = 0
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
