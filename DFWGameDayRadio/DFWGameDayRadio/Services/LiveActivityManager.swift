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
            stationName: station.displayName
        )

        let initialState = ScoreActivityAttributes.ContentState(
            homeScore: score.homeScore,
            awayScore: score.awayScore,
            gameClockDisplay: score.clockDisplay,
            gameState: score.state,
            statusDetail: score.statusDetail
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            activeActivities[team] = activity.id
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    func updateScore(_ score: GameScore, for team: DallasTeam) {
        guard let activityID = activeActivities[team] else { return }

        let state = ScoreActivityAttributes.ContentState(
            homeScore: score.homeScore,
            awayScore: score.awayScore,
            gameClockDisplay: score.clockDisplay,
            gameState: score.state,
            statusDetail: score.statusDetail
        )

        Task {
            for activity in Activity<ScoreActivityAttributes>.activities {
                if activity.id == activityID {
                    await activity.update(.init(state: state, staleDate: nil))
                    break
                }
            }
        }
    }

    func endActivity(for team: DallasTeam) {
        guard let activityID = activeActivities[team] else { return }

        Task {
            for activity in Activity<ScoreActivityAttributes>.activities {
                if activity.id == activityID {
                    await activity.end(nil, dismissalPolicy: .immediate)
                    break
                }
            }
        }

        activeActivities.removeValue(forKey: team)
    }

    func endAllActivities() {
        Task {
            for activity in Activity<ScoreActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
        activeActivities.removeAll()
    }
}
