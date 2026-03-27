import Foundation

// MARK: - Scoreboard response

struct NBAScoreboardResponse: Codable {
    let scoreboard: NBAScoreboard
}

struct NBAScoreboard: Codable {
    let games: [NBAGame]
}

struct NBAGame: Codable {
    let gameId: String
    let gameStatus: Int                 // 1=scheduled, 2=in progress, 3=final
    let gameStatusText: String          // "Q3 8:42", "Final", "7:30 pm ET"
    let period: Int
    let gameClock: String?              // "PT08M42.00S" (ISO 8601 duration) or ""
    let homeTeam: NBATeam
    let awayTeam: NBATeam
}

struct NBATeam: Codable {
    let teamId: Int
    let teamTricode: String            // "DAL", "BOS"
    let teamName: String               // "Mavericks"
    let teamCity: String               // "Dallas"
    let score: Int
    let periods: [NBAPeriod]?
    let timeoutsRemaining: Int?
    let inBonus: String?               // "1" if in bonus, nil or "0" otherwise
}

struct NBAPeriod: Codable {
    let period: Int
    let score: Int?
}
