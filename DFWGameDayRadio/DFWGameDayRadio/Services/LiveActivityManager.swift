import ActivityKit
import Foundation

@Observable
class LiveActivityManager {
    static let shared = LiveActivityManager()

    var activeActivities: [DallasTeam: String] = [:] // team -> activity ID

    private init() {}

    func startActivity(for team: DallasTeam, score: GameScore, station: RadioStation) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // End existing activity for this team first
        endActivity(for: team)

        let attributes = ScoreActivityAttributes(
            homeTeam: score.homeTeam,
            awayTeam: score.awayTeam,
            homeTeamFull: score.homeTeamFull,
            awayTeamFull: score.awayTeamFull,
            sport: team.sport,
            stationName: station.displayName,
            homeTeamColor: team.primaryColor,
            awayTeamColor: team.primaryColor
        )

        let initialState = ScoreActivityAttributes.ContentState(
            homeScore: score.homeScore,
            awayScore: score.awayScore,
            gameClockDisplay: score.clockDisplay,
            gameState: score.state,
            statusDetail: score.statusDetail,
            situation: score.situation
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            activeActivities[team] = activity.id
        } catch {
            AppLogger.liveActivity.error("Failed to start: \(error.localizedDescription)")
        }
    }

    func updateScore(_ score: GameScore, for team: DallasTeam) {
        guard let activityID = activeActivities[team] else { return }

        let state = ScoreActivityAttributes.ContentState(
            homeScore: score.homeScore,
            awayScore: score.awayScore,
            gameClockDisplay: score.clockDisplay,
            gameState: score.state,
            statusDetail: score.statusDetail,
            situation: score.situation
        )

        Task {
            for activity in Activity<ScoreActivityAttributes>.activities {
                if activity.id == activityID {
                    await activity.update(
                        ActivityContent(state: state, staleDate: nil),
                        alertConfiguration: score.isLive ? AlertConfiguration(
                            title: "\(score.homeTeam) vs \(score.awayTeam)",
                            body: "\(score.awayTeam) \(score.awayScore) - \(score.homeTeam) \(score.homeScore)",
                            sound: .default
                        ) : nil
                    )
                    break
                }
            }
        }
    }

    func endActivity(for team: DallasTeam) {
        guard let activityID = activeActivities.removeValue(forKey: team) else { return }

        Task {
            for activity in Activity<ScoreActivityAttributes>.activities {
                if activity.id == activityID {
                    await activity.end(nil, dismissalPolicy: .immediate)
                    break
                }
            }
        }
    }

    func endAllActivities() {
        let ids = Set(activeActivities.values)
        activeActivities.removeAll()

        Task {
            for activity in Activity<ScoreActivityAttributes>.activities {
                if ids.contains(activity.id) {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
        }
    }
}
