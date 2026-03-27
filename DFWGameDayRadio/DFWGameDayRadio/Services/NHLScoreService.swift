import Foundation

@Observable
class NHLScoreService: ScoreProvider {
    static let shared = NHLScoreService()

    var activeGames: [DallasTeam: GameScore] = [:]
    var lastError: String?
    var isPolling = false

    private var pollingTimer: Timer?
    private let pollingInterval: TimeInterval = 10.0
    private let session = URLSession.shared
    private var trackedTeams: [DallasTeam] = []
    private var gameIds: [DallasTeam: Int] = [:]

    private init() {}

    func startPolling(for teams: [DallasTeam]) {
        stopPolling()
        trackedTeams = teams
        isPolling = true

        Task {
            await discoverGames(for: teams)
            await fetchAllPlayByPlay()
        }

        pollingTimer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.fetchAllPlayByPlay() }
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        isPolling = false
        trackedTeams = []
        gameIds = [:]
    }

    // MARK: - Game Discovery

    private func discoverGames(for teams: [DallasTeam]) async {
        let today = ISO8601DateFormatter.dateOnly.string(from: Date())
        let urlString = "\(NHLEndpoint.scores)/\(today)"
        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(NHLScoresResponse.self, from: data)

            for team in teams {
                guard let abbrev = team.nhlAbbrev else { continue }
                if let game = response.games.first(where: {
                    $0.homeTeam.abbrev == abbrev || $0.awayTeam.abbrev == abbrev
                }) {
                    await MainActor.run {
                        self.gameIds[team] = game.id
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.lastError = "NHL scores error: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Play-by-Play Polling

    private func fetchAllPlayByPlay() async {
        for team in trackedTeams {
            guard let gameId = gameIds[team] else { continue }
            await fetchPlayByPlay(gameId: gameId, team: team)
        }
    }

    private func fetchPlayByPlay(gameId: Int, team: DallasTeam) async {
        let urlString = "\(NHLEndpoint.gamecenter)/\(gameId)/play-by-play"
        guard let url = URL(string: urlString) else { return }

        do {
            let startTime = Date()
            let (data, _) = try await session.data(from: url)
            StreamLatencyEstimator.shared.recordAPILatency(Date().timeIntervalSince(startTime))
            let pbp = try JSONDecoder().decode(NHLPlayByPlay.self, from: data)
            let score = mapToGameScore(pbp: pbp, gameId: gameId)
            await MainActor.run {
                self.activeGames[team] = score
                self.lastError = nil
            }
        } catch {
            await MainActor.run {
                self.lastError = "NHL PBP error: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Mapping

    private func mapToGameScore(pbp: NHLPlayByPlay, gameId: Int) -> GameScore {
        let homeScore = pbp.homeTeam.score ?? 0
        let awayScore = pbp.awayTeam.score ?? 0
        let period = pbp.periodDescriptor?.number ?? 0
        let timeRemaining = pbp.clock?.timeRemaining ?? ""

        let state: String
        switch pbp.gameState {
        case "LIVE", "CRIT": state = "in"
        case "OFF", "FINAL": state = "post"
        default: state = "pre"
        }

        let periodName: String
        if let periodType = pbp.periodDescriptor?.periodType, periodType == "OT" {
            periodName = "OT"
        } else if let periodType = pbp.periodDescriptor?.periodType, periodType == "SO" {
            periodName = "SO"
        } else {
            periodName = "\(period.ordinal)"
        }

        let statusDetail: String
        if state == "in" {
            if pbp.clock?.inIntermission == true {
                statusDetail = "\(periodName) Int"
            } else {
                statusDetail = "\(periodName) \(timeRemaining)"
            }
        } else if state == "post" {
            statusDetail = "Final"
        } else {
            statusDetail = "Scheduled"
        }

        // Build situation
        var situation: GameSituation?
        if state == "in" {
            let isPowerPlay = detectPowerPlay(situation: pbp.situation)

            situation = .hockey(HockeySituation(
                powerPlay: isPowerPlay.isActive,
                powerPlayTeam: isPowerPlay.team,
                powerPlayTimeRemaining: nil,
                shotsHome: pbp.homeTeam.sog ?? 0,
                shotsAway: pbp.awayTeam.sog ?? 0
            ))
        }

        return GameScore(
            eventID: String(gameId),
            homeTeam: pbp.homeTeam.abbrev,
            awayTeam: pbp.awayTeam.abbrev,
            homeTeamFull: pbp.homeTeam.name?.default ?? pbp.homeTeam.abbrev,
            awayTeamFull: pbp.awayTeam.name?.default ?? pbp.awayTeam.abbrev,
            homeScore: homeScore,
            awayScore: awayScore,
            period: period,
            displayClock: timeRemaining,
            state: state,
            statusDetail: statusDetail,
            situation: situation
        )
    }

    private func detectPowerPlay(situation: NHLSituation?) -> (isActive: Bool, team: String?) {
        guard let code = situation?.situationCode, code.count == 4 else {
            return (false, nil)
        }
        // Situation code format: "1551" = [awayGoalie, awaySkaters, homeSkaters, homeGoalie]
        let digits = code.compactMap { $0.wholeNumberValue }
        guard digits.count == 4 else { return (false, nil) }

        let awaySkaters = digits[1]
        let homeSkaters = digits[2]

        if homeSkaters > awaySkaters {
            return (true, situation?.homeTeam?.abbrev)
        } else if awaySkaters > homeSkaters {
            return (true, situation?.awayTeam?.abbrev)
        }
        return (false, nil)
    }
}

// MARK: - DallasTeam NHL extension

extension DallasTeam {
    var nhlAbbrev: String? {
        switch self {
        case .stars: return NHLTeamID.stars
        default: return nil
        }
    }
}
