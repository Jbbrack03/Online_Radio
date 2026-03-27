import Foundation

/// Sport-specific in-game situation data that enriches the basic score.
/// Used by both the main app and the widget extension.
enum GameSituation: Codable, Hashable {
    case baseball(BaseballSituation)
    case football(FootballSituation)
    case basketball(BasketballSituation)
    case hockey(HockeySituation)
}

struct BaseballSituation: Codable, Hashable {
    let inning: Int
    let inningHalf: String       // "top" or "bottom"
    let balls: Int
    let strikes: Int
    let outs: Int
    let runnerOnFirst: Bool
    let runnerOnSecond: Bool
    let runnerOnThird: Bool
    let batterName: String
    let pitcherName: String

    var inningDisplay: String {
        let half = inningHalf == "bottom" ? "Bot" : "Top"
        return "\(half) \(inning.ordinal)"
    }

    var countDisplay: String {
        "\(balls)-\(strikes)"
    }

    var outsDisplay: String {
        "\(outs) Out\(outs == 1 ? "" : "s")"
    }
}

struct FootballSituation: Codable, Hashable {
    let down: Int
    let distance: Int
    let yardLine: Int
    let possession: String       // team abbreviation
    let lastPlay: String?

    var downAndDistance: String {
        "\(down.ordinal) & \(distance)"
    }

    var fieldPosition: String {
        "\(down.ordinal) & \(distance) at \(possession) \(yardLine)"
    }
}

struct BasketballSituation: Codable, Hashable {
    let timeoutsHome: Int
    let timeoutsAway: Int
    let bonusHome: Bool
    let bonusAway: Bool
}

struct HockeySituation: Codable, Hashable {
    let powerPlay: Bool
    let powerPlayTeam: String?
    let powerPlayTimeRemaining: String?
    let shotsHome: Int
    let shotsAway: Int

    var shotsDisplay: String {
        "SOG \(shotsAway)-\(shotsHome)"
    }
}

// MARK: - Ordinal helper

extension Int {
    var ordinal: String {
        switch self {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        case 4: return "4th"
        default: return "\(self)th"
        }
    }
}
