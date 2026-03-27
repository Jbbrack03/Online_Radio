import Foundation

// MARK: - Stream URLs

enum StreamURL {
    // 105.3 The Fan (KRLD-FM) - Audacy / AmperWave
    static let krldFM = "https://live.amperwave.net/direct/audacy-krldfmaac-imc"
    static let krldFM_HLS = "https://live.amperwave.net/manifest/audacy-krldfmaac-hlsc.m3u8"

    // 97.1 The Eagle (KEGL-FM) - iHeartMedia
    static let keglFM = "https://stream.revma.ihrhls.com/zc2241"
    static let keglFM_HLS = "https://stream.revma.ihrhls.com/zc2241/hls.m3u8"

    // 96.7 The Ticket / 1310 AM (KTCK) - Cumulus / Triton Digital
    static let ktckAM = "https://playerservices.streamtheworld.com/api/livestream-redirect/KTCKAMAAC.aac?burst-time=0"
    static let ktckAM_HLS: String? = nil // No HLS endpoint available
}

// MARK: - Score API Endpoints

/// ESPN — used for NFL (no free alternative) and as fallback for other sports
enum ESPNEndpoint {
    static let base = "https://site.api.espn.com/apis/site/v2/sports"
    static let nfl = "\(base)/football/nfl/scoreboard"
    static let nflSummary = "\(base)/football/nfl/summary" // ?event={eventId}
    static let mlb = "\(base)/baseball/mlb/scoreboard"
    static let nba = "\(base)/basketball/nba/scoreboard"
    static let nhl = "\(base)/hockey/nhl/scoreboard"
}

/// MLB Stats API — richest free baseball API (balls, strikes, outs, runners, pitch-by-pitch)
enum MLBStatsEndpoint {
    static let base = "https://statsapi.mlb.com/api"
    static let schedule = "\(base)/v1/schedule" // ?sportId=1&date=YYYY-MM-DD&hydrate=linescore
    static let liveFeed = "\(base)/v1.1/game" // /{gamePk}/feed/live
}

/// NHL API — play-by-play with x/y coordinates, power play tracking
enum NHLEndpoint {
    static let base = "https://api-web.nhle.com/v1"
    static let scores = "\(base)/scores" // /{date} (YYYY-MM-DD)
    static let gamecenter = "\(base)/gamecenter" // /{gameId}/play-by-play, /landing, /boxscore
}

/// NBA CDN — play-by-play with shot coordinates, no auth required
enum NBAEndpoint {
    static let scoreboard = "https://cdn.nba.com/static/json/liveData/scoreboard/todaysScoreboard_00.json"
    static let playByPlay = "https://cdn.nba.com/static/json/liveData/playbyplay/playbyplay_" // {gameId}.json
    static let boxscore = "https://cdn.nba.com/static/json/liveData/boxscore/boxscore_" // {gameId}.json
}

// MARK: - Team Identifiers

enum ESPNTeamID {
    static let cowboys = "6"
    static let rangers = "13"
    static let mavericks = "7"
    static let stars = "25"
}

enum MLBTeamID {
    static let rangers = 13
}

enum NHLTeamID {
    static let stars = "DAL"
}

enum NBATeamID {
    static let mavericks = 1610612742
}

// MARK: - ESPN Image URLs

enum ESPNImages {
    static let teamLogo = "https://a.espncdn.com/i/teamlogos" // /{league}/500/{abbrev}.png
    static let combiner = "https://a.espncdn.com/combiner/i" // ?img=/i/teamlogos/{league}/500/{abbrev}.png&w={W}&h={H}

    static func teamLogoURL(league: String, abbreviation: String, size: Int? = nil) -> URL? {
        if let size {
            return URL(string: "\(combiner)?img=/i/teamlogos/\(league)/500/\(abbreviation).png&w=\(size)&h=\(size)")
        }
        return URL(string: "\(teamLogo)/\(league)/500/\(abbreviation).png")
    }
}

// MARK: - Layout Constants

import SwiftUI

enum LayoutConstants {
    // CarPlay
    static let carPlayLogoSize: CGFloat = 44
}
