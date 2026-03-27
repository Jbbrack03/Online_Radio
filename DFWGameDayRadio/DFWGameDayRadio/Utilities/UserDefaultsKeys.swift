import Foundation

enum UserDefaultsKeys {
    static let scoreDelay = "scoreDelaySeconds"
    static let userDelayOffset = "userDelayOffset"
    static let selectedTeams = "selectedTeams"
    static let autoStartLiveActivity = "autoStartLiveActivity"

    static func cachedLatency(for station: String) -> String {
        "streamLatency_\(station)"
    }
}
