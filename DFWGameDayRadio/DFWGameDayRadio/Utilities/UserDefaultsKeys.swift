import Foundation

enum UserDefaultsKeys {
    static let scoreDelay = "scoreDelaySeconds"
    static let userDelayOffset = "userDelayOffset"
    static let selectedTeams = "selectedTeams"
    static let autoStartLiveActivity = "autoStartLiveActivity"
    static let lastPlayedStation = "lastPlayedStation"

    static func cachedLatency(for station: String) -> String {
        "streamLatency_\(station)"
    }

    static func cachedLatencyDate(for station: String) -> String {
        "streamLatencyDate_\(station)"
    }
}
