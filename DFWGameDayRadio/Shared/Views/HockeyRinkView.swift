import SwiftUI

/// Hockey game situation showing power play status and shots on goal.
struct HockeyRinkView: View {
    let situation: HockeySituation
    var compact: Bool = false

    var body: some View {
        if compact {
            compactLayout
        } else {
            fullLayout
        }
    }

    // MARK: - Full Layout

    private var fullLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Power play indicator
            if situation.powerPlay {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption)
                    Text("Power Play")
                        .font(.subheadline.bold())
                        .foregroundStyle(.yellow)
                    if let team = situation.powerPlayTeam {
                        Text(team)
                            .font(.caption.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.yellow.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    if let time = situation.powerPlayTimeRemaining, !time.isEmpty {
                        Text(time)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Shots on goal
            shotsBar
        }
    }

    // MARK: - Compact Layout

    private var compactLayout: some View {
        HStack(spacing: 6) {
            if situation.powerPlay {
                HStack(spacing: 2) {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.yellow)
                        .font(.caption2)
                    Text("PP")
                        .font(.caption2.bold())
                        .foregroundStyle(.yellow)
                }
            }
            Text(situation.shotsDisplay)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Shots Bar

    private var shotsBar: some View {
        VStack(spacing: 4) {
            HStack {
                Text("SOG")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Spacer()
            }

            GeometryReader { geo in
                let total = max(situation.shotsHome + situation.shotsAway, 1)
                let awayWidth = geo.size.width * CGFloat(situation.shotsAway) / CGFloat(total)

                ZStack(alignment: .leading) {
                    // Full bar background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.secondary.opacity(0.2))

                    // Away team portion
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue.opacity(0.6))
                        .frame(width: max(awayWidth, 2))
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(situation.shotsAway)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(situation.shotsHome)")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
