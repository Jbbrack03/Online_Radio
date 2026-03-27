import Foundation

enum RadioStation: String, CaseIterable, Identifiable, Codable {
    case theFan = "the_fan"
    case theEagle = "the_eagle"
    case theTicket = "the_ticket"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .theFan: return "105.3 The Fan"
        case .theEagle: return "97.1 The Eagle"
        case .theTicket: return "96.7 The Ticket"
        }
    }

    var callSign: String {
        switch self {
        case .theFan: return "KRLD-FM"
        case .theEagle: return "KEGL-FM"
        case .theTicket: return "KTCK-FM"
        }
    }

    var tagline: String {
        switch self {
        case .theFan: return "Dallas Sports Radio"
        case .theEagle: return "Dallas' Rock Station"
        case .theTicket: return "The Little Ticket"
        }
    }

    var streamURL: String {
        switch self {
        case .theFan: return StreamURL.krldFM
        case .theEagle: return StreamURL.keglFM
        case .theTicket: return StreamURL.ktckAM
        }
    }

    var hlsFallbackURL: String? {
        switch self {
        case .theFan: return StreamURL.krldFM_HLS
        case .theEagle: return StreamURL.keglFM_HLS
        case .theTicket: return StreamURL.ktckAM_HLS
        }
    }

    var teams: [DallasTeam] {
        switch self {
        case .theFan: return [.cowboys, .rangers]
        case .theEagle: return [.mavericks]
        case .theTicket: return [.stars]
        }
    }
}
