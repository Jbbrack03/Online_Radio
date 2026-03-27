import Foundation
import Combine

/// Coordinates the flow: ESPN scores -> delay queue -> live activity updates.
/// Wire this up once at app launch and it handles the piping automatically.
@Observable
class GameCoordinator {
    static let shared = GameCoordinator()

    private let scoreService = ESPNScoreService.shared
    private let delayQueue = ScoreDelayQueue.shared
    private var feedTimer: Timer?

    private init() {}

    /// Call when the user starts listening to a station.
    func startTracking(station: RadioStation) {
        let teams = station.teams

        scoreService.startPolling(for: teams)
        delayQueue.startProcessing()

        // Feed ESPN scores into the delay queue periodically
        feedTimer?.invalidate()
        feedTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            for team in teams {
                if let score = self.scoreService.activeGames[team] {
                    self.delayQueue.enqueue(score, for: team)
                }
            }
        }

        // Auto-start live activities for games that are already in progress
        Task {
            try? await Task.sleep(for: .seconds(3))
            for team in teams {
                if let score = scoreService.activeGames[team], score.isLive {
                    await MainActor.run {
                        LiveActivityManager.shared.startActivity(for: team, score: score, station: station)
                    }
                }
            }
        }
    }

    /// Call when the user stops listening.
    func stopTracking() {
        feedTimer?.invalidate()
        feedTimer = nil
        scoreService.stopPolling()
        delayQueue.stopProcessing()
        delayQueue.clear()
        LiveActivityManager.shared.endAllActivities()
    }
}
