import Foundation

struct GameScore: Equatable, Codable {
    let eventID: String
    let homeTeam: String       // abbreviation e.g. "DAL"
    let awayTeam: String       // abbreviation e.g. "PHI"
    let homeTeamFull: String   // "Dallas Cowboys"
    let awayTeamFull: String   // "Philadelphia Eagles"
    let homeScore: Int
    let awayScore: Int
    let period: Int
    let displayClock: String   // "8:42"
    let state: String          // "pre", "in", "post"
    let statusDetail: String   // "Q3 8:42" or "Final" or "7:30 PM CT"

    var clockDisplay: String {
        if state == "pre" {
            return "Pregame"
        } else if state == "post" {
            return "Final"
        } else {
            return statusDetail
        }
    }

    var isLive: Bool {
        state == "in"
    }

    var scoreLine: String {
        "\(homeTeam) \(homeScore) - \(awayScore) \(awayTeam)"
    }
}

struct DelayedScoreEvent {
    let timestamp: Date
    let score: GameScore
}
