import Foundation

// MARK: - Schedule response

struct MLBSchedule: Codable {
    let dates: [MLBScheduleDate]?
}

struct MLBScheduleDate: Codable {
    let games: [MLBScheduleGame]
}

struct MLBScheduleGame: Codable {
    let gamePk: Int
    let status: MLBGameStatus
    let teams: MLBMatchupTeams
    let linescore: MLBLinescore?
}

struct MLBGameStatus: Codable {
    let abstractGameState: String  // "Preview", "Live", "Final"
    let detailedState: String?     // "In Progress", "Final", "Scheduled", etc.
}

struct MLBMatchupTeams: Codable {
    let away: MLBMatchupTeam
    let home: MLBMatchupTeam
}

struct MLBMatchupTeam: Codable {
    let team: MLBTeamInfo
    let score: Int?
}

struct MLBTeamInfo: Codable {
    let id: Int
    let name: String
    let abbreviation: String?
}

// MARK: - Live feed response

struct MLBLiveFeed: Codable {
    let gameData: MLBGameData
    let liveData: MLBLiveData
}

struct MLBGameData: Codable {
    let status: MLBGameStatus
    let datetime: MLBDatetime?
    let teams: MLBGameDataTeams
}

struct MLBDatetime: Codable {
    let dateTime: String?
}

struct MLBGameDataTeams: Codable {
    let away: MLBGameDataTeam
    let home: MLBGameDataTeam
}

struct MLBGameDataTeam: Codable {
    let id: Int
    let name: String
    let abbreviation: String
}

struct MLBLiveData: Codable {
    let linescore: MLBLinescore?
    let plays: MLBPlays?
}

// MARK: - Linescore

struct MLBLinescore: Codable {
    let currentInning: Int?
    let inningHalf: String?        // "Top" or "Bottom"
    let teams: MLBLinescoreTeams?
    let offense: MLBOffense?
    let defense: MLBDefense?
    let balls: Int?
    let strikes: Int?
    let outs: Int?
}

struct MLBLinescoreTeams: Codable {
    let home: MLBLinescoreTeam
    let away: MLBLinescoreTeam
}

struct MLBLinescoreTeam: Codable {
    let runs: Int?
    let hits: Int?
    let errors: Int?
}

struct MLBOffense: Codable {
    let batter: MLBPlayer?
    let first: MLBPlayer?
    let second: MLBPlayer?
    let third: MLBPlayer?
}

struct MLBDefense: Codable {
    let pitcher: MLBPlayer?
}

struct MLBPlayer: Codable {
    let id: Int?
    let fullName: String?
}

// MARK: - Plays

struct MLBPlays: Codable {
    let currentPlay: MLBCurrentPlay?
}

struct MLBCurrentPlay: Codable {
    let result: MLBPlayResult?
    let about: MLBPlayAbout?
    let count: MLBCount?
    let matchup: MLBMatchup?
}

struct MLBPlayResult: Codable {
    let event: String?
    let description: String?
}

struct MLBPlayAbout: Codable {
    let inning: Int?
    let halfInning: String?  // "top" or "bottom"
    let isComplete: Bool?
}

struct MLBCount: Codable {
    let balls: Int?
    let strikes: Int?
    let outs: Int?
}

struct MLBMatchup: Codable {
    let batter: MLBPlayer?
    let pitcher: MLBPlayer?
}
