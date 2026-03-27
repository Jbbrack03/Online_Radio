import ActivityKit
import Foundation

struct ScoreActivityAttributes: ActivityAttributes {
    let homeTeam: String
    let awayTeam: String
    let homeTeamFull: String
    let awayTeamFull: String
    let sport: String
    let stationName: String

    struct ContentState: Codable, Hashable {
        let homeScore: Int
        let awayScore: Int
        let gameClockDisplay: String
        let gameState: String
        let statusDetail: String
    }
}
