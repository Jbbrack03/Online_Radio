import SwiftUI

/// Basketball game situation showing timeouts and bonus status.
struct BasketballCourtView: View {
    let situation: BasketballSituation
    let homeTeam: String
    let awayTeam: String
    var compact: Bool = false

    @ScaledMetric private var timeoutDotSize: CGFloat = 5

    var body: some View {
        if compact {
            compactLayout
        } else {
            fullLayout
        }
    }

    // MARK: - Full Layout

    private var fullLayout: some View {
        VStack(spacing: 8) {
            // Timeout dots
            HStack {
                timeoutRow(team: awayTeam, remaining: situation.timeoutsAway, total: 7, isBonus: situation.bonusAway)
                Spacer()
                timeoutRow(team: homeTeam, remaining: situation.timeoutsHome, total: 7, isBonus: situation.bonusHome)
            }
        }
    }

    // MARK: - Compact Layout

    private var compactLayout: some View {
        HStack(spacing: 8) {
            if situation.bonusAway {
                bonusBadge(team: awayTeam)
            }
            if situation.bonusHome {
                bonusBadge(team: homeTeam)
            }
            if !situation.bonusAway && !situation.bonusHome {
                Text("TO: \(awayTeam) \(situation.timeoutsAway) – \(homeTeam) \(situation.timeoutsHome)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Components

    private func timeoutRow(team: String, remaining: Int, total: Int, isBonus: Bool) -> some View {
        VStack(alignment: .center, spacing: 4) {
            HStack(spacing: 2) {
                Text(team)
                    .font(.caption2.bold())
                if isBonus {
                    Text("BONUS")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.red.opacity(0.2))
                        .foregroundStyle(.red)
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 3) {
                ForEach(0..<total, id: \.self) { i in
                    Circle()
                        .fill(i < remaining ? Color.primary.opacity(0.7) : Color.secondary.opacity(0.2))
                        .frame(width: timeoutDotSize, height: timeoutDotSize)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(team) has \(remaining) timeouts remaining\(isBonus ? ", in the bonus" : "")")
    }

    private func bonusBadge(team: String) -> some View {
        HStack(spacing: 2) {
            Text(team)
                .font(.caption2.bold())
            Text("BNS")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.red)
        }
    }
}
