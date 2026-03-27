import Foundation

@Observable
class NBAScoreService: ScoreProvider {
    static let shared = NBAScoreService()

    var activeGames: [DallasTeam: GameScore] = [:]
    var lastError: String?
    var isPolling = false

    private var pollingTimer: Timer?
    private let pollingInterval: TimeInterval = 10.0
    private let session = URLSession.shared
    private var trackedTeams: [DallasTeam] = []

    private init() {}

    func startPolling(for teams: [DallasTeam]) {
        stopPolling()
        trackedTeams = teams
        isPolling = true

        Task { await fetchScoreboard() }

        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.fetchScoreboard() }
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        isPolling = false
        trackedTeams = []
    }

    // MARK: - Fetch

    private func fetchScoreboard() async {
        guard let url = URL(string: NBAEndpoint.scoreboard) else { return }

        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(NBAScoreboardResponse.self, from: data)

            for team in trackedTeams {
                guard let nbaTeamId = team.nbaTeamID else { continue }
                if let game = response.scoreboard.games.first(where: {
                    $0.homeTeam.teamId == nbaTeamId || $0.awayTeam.teamId == nbaTeamId
                }) {
                    let score = mapToGameScore(game: game)
                    await MainActor.run {
                        self.activeGames[team] = score
                        self.lastError = nil
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.lastError = "NBA scoreboard error: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Mapping

    private func mapToGameScore(game: NBAGame) -> GameScore {
        let state: String
        switch game.gameStatus {
        case 2: state = "in"
        case 3: state = "post"
        default: state = "pre"
        }

        let displayClock = parseGameClock(game.gameClock)

        let statusDetail: String
        if state == "in" {
            statusDetail = "Q\(game.period) \(displayClock)"
        } else if state == "post" {
            statusDetail = "Final"
        } else {
            statusDetail = game.gameStatusText
        }

        // Build situation
        var situation: GameSituation?
        if state == "in" {
            situation = .basketball(BasketballSituation(
                timeoutsHome: game.homeTeam.timeoutsRemaining ?? 0,
                timeoutsAway: game.awayTeam.timeoutsRemaining ?? 0,
                bonusHome: game.homeTeam.inBonus == "1",
                bonusAway: game.awayTeam.inBonus == "1"
            ))
        }

        return GameScore(
            eventID: game.gameId,
            homeTeam: game.homeTeam.teamTricode,
            awayTeam: game.awayTeam.teamTricode,
            homeTeamFull: "\(game.homeTeam.teamCity) \(game.homeTeam.teamName)",
            awayTeamFull: "\(game.awayTeam.teamCity) \(game.awayTeam.teamName)",
            homeScore: game.homeTeam.score,
            awayScore: game.awayTeam.score,
            period: game.period,
            displayClock: displayClock,
            state: state,
            statusDetail: statusDetail,
            situation: situation
        )
    }

    /// Parse NBA's ISO 8601 duration game clock (e.g., "PT08M42.00S") to "8:42"
    private func parseGameClock(_ clock: String?) -> String {
        guard let clock, !clock.isEmpty else { return "" }

        // Format: PT08M42.00S or PT02M05.30S
        var remaining = clock.dropFirst(2) // Remove "PT"
        let minutes: Int
        let seconds: Int

        if let mIdx = remaining.firstIndex(of: "M") {
            minutes = Int(remaining[remaining.startIndex..<mIdx]) ?? 0
            remaining = remaining[remaining.index(after: mIdx)...]
        } else {
            minutes = 0
        }

        if let sIdx = remaining.firstIndex(of: "S") {
            let secStr = remaining[remaining.startIndex..<sIdx]
            seconds = Int(Double(secStr) ?? 0)
        } else {
            seconds = 0
        }

        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

// MARK: - DallasTeam NBA extension

extension DallasTeam {
    var nbaTeamID: Int? {
        switch self {
        case .mavericks: return NBATeamID.mavericks
        default: return nil
        }
    }
}
