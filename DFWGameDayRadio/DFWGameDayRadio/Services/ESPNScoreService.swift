import Foundation

@Observable
class ESPNScoreService {
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

    private func findGame(for team: DallasTeam, in scoreboard: ESPNScoreboard) -> GameScore? {
        for event in scoreboard.events {
            let competitors = event.competitions.first?.competitors ?? []
            let matchesTeam = competitors.contains { $0.team.id == team.espnTeamID }

            if matchesTeam {
                guard let home = event.homeCompetitor,
                      let away = event.awayCompetitor else { continue }

                let statusDetail = event.status.type.shortDetail ?? event.status.type.detail ?? ""

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
                    statusDetail: statusDetail
                )
            }
        }
        return nil
    }
}
