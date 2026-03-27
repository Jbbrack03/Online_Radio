import Foundation

@Observable
class ESPNScoreService: ScoreProvider {
    static let shared = ESPNScoreService()

    var activeGames: [DallasTeam: GameScore] = [:]
    var lastError: String?
    var isPolling = false

    private var pollingTimer: Timer?
    private let pollingInterval: TimeInterval = 10.0
    private let session = URLSession.shared

    private init() {}

    func startPolling(for teams: [DallasTeam] = DallasTeam.allCases) {
        stopPolling()
        isPolling = true

        // Fetch immediately, then on interval
        Task { await fetchAllScores(for: teams) }

        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.fetchAllScores(for: teams) }
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        isPolling = false
    }

    func fetchAllScores(for teams: [DallasTeam] = DallasTeam.allCases) async {
        // Group teams by endpoint to avoid duplicate requests
        let teamsByEndpoint = Dictionary(grouping: teams, by: { $0.espnEndpoint })

        await withTaskGroup(of: (String, ESPNScoreboard?).self) { group in
            for (endpoint, _) in teamsByEndpoint {
                group.addTask {
                    let scoreboard = await self.fetchScoreboard(endpoint: endpoint)
                    return (endpoint, scoreboard)
                }
            }

            for await (endpoint, scoreboard) in group {
                guard let scoreboard else { continue }
                let teamsForEndpoint = teamsByEndpoint[endpoint] ?? []
                for team in teamsForEndpoint {
                    if let game = findGame(for: team, in: scoreboard) {
                        await MainActor.run {
                            self.activeGames[team] = game
                        }
                    }
                }
            }
        }
    }

    private func fetchScoreboard(endpoint: String) async -> ESPNScoreboard? {
        guard let url = URL(string: endpoint) else { return nil }

        do {
            let (data, _) = try await session.data(from: url)
            let scoreboard = try JSONDecoder().decode(ESPNScoreboard.self, from: data)
            await MainActor.run { self.lastError = nil }
            return scoreboard
        } catch {
            await MainActor.run {
                self.lastError = "ESPN fetch error: \(error.localizedDescription)"
            }
            return nil
        }
    }

    /// Extract NFL situation data from ESPN's competition.situation field.
    private func extractSituation(from event: ESPNEvent) -> GameSituation? {
        guard let competition = event.competitions.first,
              let situation = competition.situation,
              event.status.type.state == "in" else {
            return nil
        }

        // Parse "3rd & 7 at DAL 45" format
        if let downText = situation.downDistanceText {
            let parts = parseDownDistance(downText)
            return .football(FootballSituation(
                down: parts.down,
                distance: parts.distance,
                yardLine: parts.yardLine,
                possession: situation.possessionText ?? "",
                lastPlay: situation.lastPlay?.text
            ))
        }
        return nil
    }

    private func parseDownDistance(_ text: String) -> (down: Int, distance: Int, yardLine: Int) {
        // Expected format: "3rd & 7 at DAL 45" or "1st & 10 at 50"
        var down = 0, distance = 0, yardLine = 0

        let lowered = text.lowercased()
        if lowered.hasPrefix("1st") { down = 1 }
        else if lowered.hasPrefix("2nd") { down = 2 }
        else if lowered.hasPrefix("3rd") { down = 3 }
        else if lowered.hasPrefix("4th") { down = 4 }

        // Extract distance after "& "
        if let ampIdx = text.range(of: "& ") {
            let afterAmp = text[ampIdx.upperBound...]
            let distStr = afterAmp.prefix(while: { $0.isNumber })
            distance = Int(distStr) ?? 0
        }

        // Extract yard line (last number in string)
        let numbers = text.split(separator: " ").compactMap { Int($0) }
        if let last = numbers.last {
            yardLine = last
        }

        return (down, distance, yardLine)
    }

    private func findGame(for team: DallasTeam, in scoreboard: ESPNScoreboard) -> GameScore? {
        for event in scoreboard.events {
            let competitors = event.competitions.first?.competitors ?? []
            let matchesTeam = competitors.contains { $0.team.id == team.espnTeamID }

            if matchesTeam {
                guard let home = event.homeCompetitor,
                      let away = event.awayCompetitor else { continue }

                let statusDetail = event.status.type.shortDetail ?? event.status.type.detail ?? ""
                let situation = extractSituation(from: event)

                return GameScore(
                    eventID: event.id,
                    homeTeam: home.team.abbreviation,
                    awayTeam: away.team.abbreviation,
                    homeTeamFull: home.team.displayName,
                    awayTeamFull: away.team.displayName,
                    homeScore: home.scoreInt,
                    awayScore: away.scoreInt,
                    period: event.status.period ?? 0,
                    displayClock: event.status.displayClock ?? "",
                    state: event.status.type.state,
                    statusDetail: statusDetail,
                    situation: situation
                )
            }
        }
        return nil
    }
}
