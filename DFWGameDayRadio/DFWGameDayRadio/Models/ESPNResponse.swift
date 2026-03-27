import Foundation

// MARK: - Top-level scoreboard response

struct ESPNScoreboard: Codable {
    let events: [ESPNEvent]
}

struct ESPNEvent: Codable, Identifiable {
    let id: String
    let name: String
    let shortName: String
    let status: ESPNStatus
    let competitions: [ESPNCompetition]

    var homeCompetitor: ESPNCompetitor? {
        competitions.first?.competitors.first(where: { $0.homeAway == "home" })
    }

    var awayCompetitor: ESPNCompetitor? {
        competitions.first?.competitors.first(where: { $0.homeAway == "away" })
    }
}

struct ESPNStatus: Codable {
    let clock: Double?
    let displayClock: String?
    let period: Int?
    let type: ESPNStatusType
}

struct ESPNStatusType: Codable {
    let id: String?
    let name: String?
    let state: String  // "pre", "in", "post"
    let completed: Bool?
    let description: String?
    let detail: String?
    let shortDetail: String?
}

struct ESPNCompetition: Codable {
    let competitors: [ESPNCompetitor]
    let situation: ESPNSituation?
}

struct ESPNSituation: Codable {
    let lastPlay: ESPNLastPlay?
    let downDistanceText: String?
    let possessionText: String?
}

struct ESPNLastPlay: Codable {
    let text: String?
}

struct ESPNCompetitor: Codable {
    let id: String
    let homeAway: String
    let score: String?
    let team: ESPNTeam
    let linescores: [ESPNLineScore]?

    var scoreInt: Int {
        Int(score ?? "0") ?? 0
    }
}

struct ESPNTeam: Codable {
    let id: String
    let abbreviation: String
    let displayName: String
    let shortDisplayName: String
    let logo: String?
    let color: String?
}

struct ESPNLineScore: Codable {
    let value: Double?
}
