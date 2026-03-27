import Foundation

/// Protocol for swappable score data providers.
/// GameCoordinator selects the right provider per sport.
protocol ScoreProvider: AnyObject {
    var activeGames: [DallasTeam: GameScore] { get }
    var lastError: String? { get }
    func startPolling(for teams: [DallasTeam])
    func stopPolling()
}
