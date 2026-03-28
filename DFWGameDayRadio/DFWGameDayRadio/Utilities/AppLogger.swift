import os

enum AppLogger {
    static let audio = Logger(subsystem: "com.personal.DFWGameDayRadio", category: "Audio")
    static let scores = Logger(subsystem: "com.personal.DFWGameDayRadio", category: "Scores")
    static let liveActivity = Logger(subsystem: "com.personal.DFWGameDayRadio", category: "LiveActivity")
    static let network = Logger(subsystem: "com.personal.DFWGameDayRadio", category: "Network")
}
