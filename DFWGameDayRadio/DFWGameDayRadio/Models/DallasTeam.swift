import Foundation

enum DallasTeam: String, CaseIterable, Identifiable, Codable {
    case cowboys
    case rangers
    case mavericks
    case stars

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cowboys: return "Dallas Cowboys"
        case .rangers: return "Texas Rangers"
        case .mavericks: return "Dallas Mavericks"
        case .stars: return "Dallas Stars"
        }
    }

    var shortName: String {
        switch self {
        case .cowboys: return "Cowboys"
        case .rangers: return "Rangers"
        case .mavericks: return "Mavs"
        case .stars: return "Stars"
        }
    }

    var abbreviation: String {
        switch self {
        case .cowboys: return "DAL"
        case .rangers: return "TEX"
        case .mavericks: return "DAL"
        case .stars: return "DAL"
        }
    }

    var espnTeamID: String {
        switch self {
        case .cowboys: return ESPNTeamID.cowboys
        case .rangers: return ESPNTeamID.rangers
        case .mavericks: return ESPNTeamID.mavericks
        case .stars: return ESPNTeamID.stars
        }
    }

    var espnEndpoint: String {
        switch self {
        case .cowboys: return ESPNEndpoint.nfl
        case .rangers: return ESPNEndpoint.mlb
        case .mavericks: return ESPNEndpoint.nba
        case .stars: return ESPNEndpoint.nhl
        }
    }

    var sport: String {
        switch self {
        case .cowboys: return "NFL"
        case .rangers: return "MLB"
        case .mavericks: return "NBA"
        case .stars: return "NHL"
        }
    }

    var station: RadioStation {
        switch self {
        case .cowboys, .rangers: return .theFan
        case .mavericks: return .theEagle
        case .stars: return .theTicket
        }
    }

    var primaryColor: String {
        switch self {
        case .cowboys: return "#003594"
        case .rangers: return "#003278"
        case .mavericks: return "#00538C"
        case .stars: return "#006847"
        }
    }
}
