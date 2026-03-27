import Foundation

enum StreamURL {
    // 105.3 The Fan (KRLD-FM) - Audacy
    static let krldFM = "https://playerservices.streamtheworld.com/api/livestream-redirect/KRLDFMAAC.aac"
    // 97.1 The Eagle (KEGL-FM) - iHeartMedia
    static let keglFM = "https://playerservices.streamtheworld.com/api/livestream-redirect/KEGLFMAAC.aac"
    // 96.7 The Ticket / 1310 AM (KTCK) - Cumulus
    static let ktckAM = "https://playerservices.streamtheworld.com/api/livestream-redirect/KTCKAMAAC.aac"
}

enum ESPNEndpoint {
    static let base = "https://site.api.espn.com/apis/site/v2/sports"
    static let nfl = "\(base)/football/nfl/scoreboard"
    static let mlb = "\(base)/baseball/mlb/scoreboard"
    static let nba = "\(base)/basketball/nba/scoreboard"
    static let nhl = "\(base)/hockey/nhl/scoreboard"
}

enum ESPNTeamID {
    static let cowboys = "6"
    static let rangers = "13"
    static let mavericks = "7"
    static let stars = "25"
}
