import Foundation

@Observable
class MLBScoreService: ScoreProvider {
    static let shared = MLBScoreService()

    var activeGames: [DallasTeam: GameScore] = [:]
    var lastError: String?
    var isPolling = false

    private var pollingTimer: Timer?
    private let pollingInterval: TimeInterval = 10.0
    private let session = URLSession.shared
    private var trackedTeams: [DallasTeam] = []
    private var gamePks: [DallasTeam: Int] = [:]

    private init() {}

    func startPolling(for teams: [DallasTeam]) {
        stopPolling()
        trackedTeams = teams
        isPolling = true

        Task {
            await discoverGames(for: teams)
            await fetchAllLiveFeeds()
        }

        let timer = Timer(timeInterval: pollingInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.fetchAllLiveFeeds() }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollingTimer = timer
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        isPolling = false
        trackedTeams = []
        gamePks = [:]
    }

    // MARK: - Schedule Discovery

    private func discoverGames(for teams: [DallasTeam]) async {
        let today = ISO8601DateFormatter.dateOnly.string(from: Date())

        for team in teams {
            guard let mlbTeamId = team.mlbTeamID else { continue }
            let urlString = "\(MLBStatsEndpoint.schedule)?sportId=1&date=\(today)&teamId=\(mlbTeamId)&hydrate=linescore"
            guard let url = URL(string: urlString) else { continue }

            do {
                let schedule = try await NetworkRetry.withBackoff {
                    let (data, _) = try await self.session.data(from: url)
                    return try JSONDecoder().decode(MLBSchedule.self, from: data)
                }
                if let game = schedule.dates?.first?.games.first {
                    await MainActor.run {
                        self.gamePks[team] = game.gamePk
                    }
                } else {
                    await MainActor.run {
                        self.activeGames[team] = nil
                    }
                }
            } catch {
                await MainActor.run {
                    self.lastError = "MLB schedule error: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Live Feed Polling

    private func fetchAllLiveFeeds() async {
        for team in trackedTeams {
            guard let gamePk = gamePks[team] else { continue }
            await fetchLiveFeed(gamePk: gamePk, team: team)
        }
    }

    private func fetchLiveFeed(gamePk: Int, team: DallasTeam) async {
        let urlString = "\(MLBStatsEndpoint.liveFeed)/\(gamePk)/feed/live"
        guard let url = URL(string: urlString) else { return }

        do {
            let (feed, score) = try await NetworkRetry.withBackoff {
                let startTime = Date()
                let (data, _) = try await self.session.data(from: url)
                StreamLatencyEstimator.shared.recordAPILatency(Date().timeIntervalSince(startTime))
                let feed = try JSONDecoder().decode(MLBLiveFeed.self, from: data)
                let score = self.mapToGameScore(feed: feed, gamePk: gamePk)
                return (feed, score)
            }
            await MainActor.run {
                self.activeGames[team] = score
                self.lastError = nil
            }
        } catch {
            await MainActor.run {
                self.lastError = "MLB feed error: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Mapping

    private func mapToGameScore(feed: MLBLiveFeed, gamePk: Int) -> GameScore {
        let gameData = feed.gameData
        let linescore = feed.liveData.linescore
        let plays = feed.liveData.plays

        let homeRuns = linescore?.teams?.home.runs ?? 0
        let awayRuns = linescore?.teams?.away.runs ?? 0
        let inning = linescore?.currentInning ?? 0
        let inningHalf = linescore?.inningHalf ?? ""

        let state: String
        switch gameData.status.abstractGameState {
        case "Live": state = "in"
        case "Final": state = "post"
        default: state = "pre"
        }

        let statusDetail: String
        if state == "in" {
            let half = inningHalf == "Bottom" ? "Bot" : "Top"
            statusDetail = "\(half) \(inning.ordinal)"
        } else if state == "post" {
            statusDetail = "Final"
        } else {
            statusDetail = gameData.status.detailedState ?? "Scheduled"
        }

        // Build situation
        var situation: GameSituation?
        if state == "in", let ls = linescore {
            let count = plays?.currentPlay?.count
            let matchup = plays?.currentPlay?.matchup

            situation = .baseball(BaseballSituation(
                inning: ls.currentInning ?? 0,
                inningHalf: (ls.inningHalf ?? "Top").lowercased(),
                balls: count?.balls ?? ls.balls ?? 0,
                strikes: count?.strikes ?? ls.strikes ?? 0,
                outs: count?.outs ?? ls.outs ?? 0,
                runnerOnFirst: ls.offense?.first != nil,
                runnerOnSecond: ls.offense?.second != nil,
                runnerOnThird: ls.offense?.third != nil,
                batterName: matchup?.batter?.fullName ?? ls.offense?.batter?.fullName ?? "",
                pitcherName: matchup?.pitcher?.fullName ?? ls.defense?.pitcher?.fullName ?? ""
            ))
        }

        return GameScore(
            eventID: String(gamePk),
            homeTeam: gameData.teams.home.abbreviation,
            awayTeam: gameData.teams.away.abbreviation,
            homeTeamFull: gameData.teams.home.name,
            awayTeamFull: gameData.teams.away.name,
            homeScore: homeRuns,
            awayScore: awayRuns,
            period: inning,
            displayClock: "",
            state: state,
            statusDetail: statusDetail,
            situation: situation
        )
    }
}

// MARK: - DallasTeam MLB extension

extension DallasTeam {
    var mlbTeamID: Int? {
        switch self {
        case .rangers: return MLBTeamID.rangers
        default: return nil
        }
    }
}

// MARK: - Date formatter

extension ISO8601DateFormatter {
    static let dateOnly: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate, .withDashSeparatorInDate]
        return f
    }()
}
