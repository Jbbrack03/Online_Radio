import Foundation

/// Central hub that coordinates audio playback, score tracking, delay queue, and live activities.
/// All playback and score-tracking actions should go through this coordinator.
@Observable
class GameCoordinator {
    static let shared = GameCoordinator()

    var currentStation: RadioStation?
    var isTracking = false

    private let audioManager = AudioStreamManager.shared
    private let delayQueue = ScoreDelayQueue.shared
    private let liveActivityManager = LiveActivityManager.shared
    private let latencyEstimator = StreamLatencyEstimator.shared
    private var feedTimer: Timer?
    private var activeProviders: [DallasTeam: ScoreProvider] = [:]
    private var wasPlaying = false

    private init() {}

    // MARK: - Public API

    /// Start playing a station and tracking scores for its teams.
    func playAndTrack(station: RadioStation) {
        // If same station, just toggle play/pause
        if currentStation == station {
            togglePlayPause()
            return
        }

        // Stop any existing tracking first
        if isTracking {
            stopPlayback()
        }

        currentStation = station
        audioManager.play(station: station)
        startTracking(station: station)
    }

    /// Toggle play/pause on the current stream.
    func togglePlayPause() {
        audioManager.togglePlayPause()
    }

    /// Stop everything — audio, polling, delay queue, live activities.
    func stopPlayback() {
        stopTracking()
        audioManager.stop()
        currentStation = nil
    }

    // MARK: - Audio State (forwarded from AudioStreamManager)

    var isPlaying: Bool { audioManager.isPlaying }
    var isBuffering: Bool { audioManager.isBuffering }
    var audioError: String? { audioManager.error }

    // MARK: - Score State

    var delayedScores: [DallasTeam: GameScore] { delayQueue.delayedScores }

    /// Aggregate errors from all active providers.
    var activeErrors: [String] {
        var errors: [String] = []
        var seen = Set<ObjectIdentifier>()
        for (_, provider) in activeProviders {
            let id = ObjectIdentifier(provider)
            guard !seen.contains(id) else { continue }
            seen.insert(id)
            if let error = provider.lastError {
                errors.append(error)
            }
        }
        if let audioErr = audioError {
            errors.append(audioErr)
        }
        return errors
    }

    /// Aggregate active games from all active providers.
    var activeGames: [DallasTeam: GameScore] {
        var games: [DallasTeam: GameScore] = [:]
        for (team, provider) in activeProviders {
            if let score = provider.activeGames[team] {
                games[team] = score
            }
        }
        return games
    }

    // MARK: - Provider Selection

    /// Returns the best score provider for a given team.
    private static func provider(for team: DallasTeam) -> ScoreProvider {
        switch team {
        case .rangers: return MLBScoreService.shared
        case .stars: return NHLScoreService.shared
        case .mavericks: return NBAScoreService.shared
        case .cowboys: return ESPNScoreService.shared
        }
    }

    // MARK: - Private

    private func startTracking(station: RadioStation) {
        let teams = station.teams
        isTracking = true

        delayQueue.currentStation = station
        latencyEstimator.probe(station: station)
        delayQueue.startProcessing()

        // Start the right provider for each team
        // Group teams by provider to avoid starting the same provider twice
        var providerTeams: [ObjectIdentifier: (provider: ScoreProvider, teams: [DallasTeam])] = [:]
        for team in teams {
            let provider = Self.provider(for: team)
            activeProviders[team] = provider
            let id = ObjectIdentifier(provider)
            if providerTeams[id] != nil {
                providerTeams[id]?.teams.append(team)
            } else {
                providerTeams[id] = (provider, [team])
            }
        }

        for (_, entry) in providerTeams {
            entry.provider.startPolling(for: entry.teams)
        }

        // Feed scores from all providers into the delay queue
        feedTimer?.invalidate()
        wasPlaying = true
        feedTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }

            // Sync delay queue with audio play state
            let playing = self.audioManager.isPlaying
            if playing != self.wasPlaying {
                self.wasPlaying = playing
                if playing {
                    self.delayQueue.startProcessing()
                } else {
                    self.delayQueue.stopProcessing()
                }
            }

            for team in teams {
                if let provider = self.activeProviders[team],
                   let score = provider.activeGames[team] {
                    self.delayQueue.enqueue(score, for: team)
                }
            }
        }

        // Auto-start live activities for games already in progress
        Task {
            try? await Task.sleep(for: .seconds(3))
            for team in teams {
                if let provider = activeProviders[team],
                   let score = provider.activeGames[team],
                   score.isLive {
                    await MainActor.run {
                        liveActivityManager.startActivity(for: team, score: score, station: station)
                    }
                }
            }
        }
    }

    private func stopTracking() {
        feedTimer?.invalidate()
        feedTimer = nil
        latencyEstimator.stopProbing()

        // Stop all active providers
        var stoppedProviders = Set<ObjectIdentifier>()
        for (_, provider) in activeProviders {
            let id = ObjectIdentifier(provider)
            if !stoppedProviders.contains(id) {
                provider.stopPolling()
                stoppedProviders.insert(id)
            }
        }
        activeProviders.removeAll()

        delayQueue.stopProcessing()
        delayQueue.clear()
        liveActivityManager.endAllActivities()
        isTracking = false
    }
}
