import Foundation

// MARK: - Scores endpoint response

struct NHLScoresResponse: Codable {
    let games: [NHLScoresGame]
}

struct NHLScoresGame: Codable {
    let id: Int
    let gameState: String             // "LIVE", "OFF", "FINAL", "FUT", "PRE"
    let homeTeam: NHLScoresTeam
    let awayTeam: NHLScoresTeam
    let clock: NHLClock?
    let periodDescriptor: NHLPeriodDescriptor?
    let situation: NHLSituation?
}

struct NHLScoresTeam: Codable {
    let id: Int
    let abbrev: String
    let name: NHLTeamName?
    let score: Int?
    let sog: Int?                     // shots on goal
}

struct NHLTeamName: Codable {
    let `default`: String?

    enum CodingKeys: String, CodingKey {
        case `default` = "default"
    }
}

struct NHLClock: Codable {
    let timeRemaining: String?        // "08:42"
    let running: Bool?
    let inIntermission: Bool?
}

struct NHLPeriodDescriptor: Codable {
    let number: Int?
    let periodType: String?           // "REG", "OT", "SO"
}

struct NHLSituation: Codable {
    let homeTeam: NHLSituationTeam?
    let awayTeam: NHLSituationTeam?
    let situationCode: String?        // e.g. "1551" (goalie, skaters for each team)
}

struct NHLSituationTeam: Codable {
    let abbrev: String?
    let strength: Int?
}

// MARK: - Play-by-play endpoint response

struct NHLPlayByPlay: Codable {
    let id: Int
    let gameState: String
    let homeTeam: NHLPBPTeam
    let awayTeam: NHLPBPTeam
    let clock: NHLClock?
    let periodDescriptor: NHLPeriodDescriptor?
    let situation: NHLSituation?
    let plays: [NHLPlay]?
}

struct NHLPBPTeam: Codable {
    let id: Int
    let abbrev: String
    let name: NHLTeamName?
    let score: Int?
    let sog: Int?
}

struct NHLPlay: Codable {
    let eventId: Int?
    let typeDescKey: String?          // "goal", "shot-on-goal", "hit", etc.
    let periodDescriptor: NHLPeriodDescriptor?
    let timeInPeriod: String?
    let timeRemaining: String?
    let situationCode: String?
    let details: NHLPlayDetails?
}

struct NHLPlayDetails: Codable {
    let xCoord: Int?
    let yCoord: Int?
    let zoneCode: String?             // "O", "D", "N"
    let shotType: String?
    let scoringPlayerId: Int?
    let goalieInNetId: Int?
}
