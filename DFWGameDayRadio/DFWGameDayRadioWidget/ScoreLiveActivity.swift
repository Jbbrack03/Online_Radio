import ActivityKit
import SwiftUI
import WidgetKit

struct ScoreLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ScoreActivityAttributes.self) { context in
            // MARK: - Lock Screen / StandBy banner
            lockScreenView(context: context)

        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: - Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    teamColumn(
                        abbreviation: context.attributes.awayTeam,
                        score: context.state.awayScore
                    )
                }

                DynamicIslandExpandedRegion(.trailing) {
                    teamColumn(
                        abbreviation: context.attributes.homeTeam,
                        score: context.state.homeScore
                    )
                }

                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        if context.state.gameState == "in" {
                            Circle()
                                .fill(.red)
                                .frame(width: 6, height: 6)
                        }
                        Text(context.state.gameClockDisplay)
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    // Show situation data if available, otherwise station name
                    if let situation = context.state.situation {
                        SituationView(
                            situation: situation,
                            homeTeam: context.attributes.homeTeam,
                            awayTeam: context.attributes.awayTeam,
                            compact: true
                        )
                    } else {
                        HStack {
                            Image(systemName: "radio")
                                .font(.caption2)
                            Text(context.attributes.stationName)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            } compactLeading: {
                // MARK: - Compact Leading
                HStack(spacing: 4) {
                    Text(context.attributes.awayTeam)
                        .font(.caption2.bold())
                    Text("\(context.state.awayScore)")
                        .font(.caption.bold().monospacedDigit())
                        .contentTransition(.numericText())
                }
            } compactTrailing: {
                // MARK: - Compact Trailing
                HStack(spacing: 4) {
                    Text("\(context.state.homeScore)")
                        .font(.caption.bold().monospacedDigit())
                        .contentTransition(.numericText())
                    Text(context.attributes.homeTeam)
                        .font(.caption2.bold())
                }
            } minimal: {
                // MARK: - Minimal (when multiple activities)
                Text("\(context.state.awayScore)-\(context.state.homeScore)")
                    .font(.caption2.bold().monospacedDigit())
                    .contentTransition(.numericText())
            }
        }
    }

    // MARK: - Lock Screen Banner View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<ScoreActivityAttributes>) -> some View {
        VStack(spacing: 8) {
            // Score row
            HStack {
                // Away team
                VStack(spacing: 4) {
                    Text(context.attributes.awayTeam)
                        .font(.headline.bold())
                    Text("\(context.state.awayScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity)

                // Center: game info
                VStack(spacing: 4) {
                    if context.state.gameState == "in" {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                    }
                    Text(context.state.gameClockDisplay)
                        .font(.subheadline.bold())
                    Text(context.attributes.sport)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Home team
                VStack(spacing: 4) {
                    Text(context.attributes.homeTeam)
                        .font(.headline.bold())
                    Text("\(context.state.homeScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity)
            }

            // Situation data
            if let situation = context.state.situation {
                Divider()
                    .background(.white.opacity(0.2))
                SituationView(
                    situation: situation,
                    homeTeam: context.attributes.homeTeam,
                    awayTeam: context.attributes.awayTeam,
                    compact: true
                )
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "radio")
                        .font(.caption2)
                    Text(context.attributes.stationName)
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.7))
    }

    // MARK: - Helpers

    @ViewBuilder
    private func teamColumn(abbreviation: String, score: Int) -> some View {
        VStack(spacing: 2) {
            Text(abbreviation)
                .font(.caption.bold())
            Text("\(score)")
                .font(.title2.bold().monospacedDigit())
                .contentTransition(.numericText())
        }
    }
}
