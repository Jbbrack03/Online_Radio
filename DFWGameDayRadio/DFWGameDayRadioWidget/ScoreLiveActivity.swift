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
                        // Sport icon
                        Image(systemName: sportIcon(for: context.attributes.sport))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)

                        if context.state.gameState == "in" {
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(.red)
                                    .frame(width: 6, height: 6)
                                Text("LIVE")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.red)
                            }
                        }
                        Text(context.state.gameClockDisplay)
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    if let situation = context.state.situation {
                        Text(situation.microSummary)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
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
            } compactLeading: {
                // MARK: - Compact Leading
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color(hex: context.attributes.awayTeamColor))
                        .frame(width: 4, height: 4)
                    Text(context.attributes.awayTeam)
                        .font(.caption2.bold())
                    Text("\(context.state.awayScore)")
                        .font(.caption.bold().monospacedDigit())
                        .contentTransition(.numericText())
                }
            } compactTrailing: {
                // MARK: - Compact Trailing
                HStack(spacing: 3) {
                    Text("\(context.state.homeScore)")
                        .font(.caption.bold().monospacedDigit())
                        .contentTransition(.numericText())
                    Text(context.attributes.homeTeam)
                        .font(.caption2.bold())
                    Circle()
                        .fill(Color(hex: context.attributes.homeTeamColor))
                        .frame(width: 4, height: 4)
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
            // Score row in concentric rounded container
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
                        HStack(spacing: 3) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                            Text("LIVE")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                        }
                    }
                    Text(context.state.gameClockDisplay)
                        .font(.subheadline.bold())
                    Text(context.attributes.sport)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
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
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.1))
            )

            // Situation micro-summary or station name
            if let situation = context.state.situation {
                Text(situation.microSummary)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.8))
                    .lineLimit(1)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "radio")
                        .font(.caption2)
                    Text(context.attributes.stationName)
                        .font(.caption2)
                }
                .foregroundStyle(.white.opacity(0.6))
            }
        }
        .foregroundStyle(.white)
        .padding(14) // HIG: 14pt margins on all edges
        .activityBackgroundTint(Color(hex: context.attributes.homeTeamColor))
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

    private func sportIcon(for sport: String) -> String {
        switch sport {
        case "NFL": return "football"
        case "MLB": return "baseball"
        case "NBA": return "basketball"
        case "NHL": return "hockey.puck"
        default: return "sportscourt"
        }
    }
}

// MARK: - Color from hex (Widget extension needs its own copy)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        r = Double((int >> 16) & 0xFF) / 255.0
        g = Double((int >> 8) & 0xFF) / 255.0
        b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
