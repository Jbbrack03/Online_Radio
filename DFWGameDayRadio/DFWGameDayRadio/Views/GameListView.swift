import SwiftUI

struct GameListView: View {
    @State private var scoreService = ESPNScoreService.shared
    @State private var delayQueue = ScoreDelayQueue.shared
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List {
                if scoreService.activeGames.isEmpty && !isLoading {
                    ContentUnavailableView(
                        "No Games Today",
                        systemImage: "sportscourt",
                        description: Text("No Dallas team games found on today's schedule.")
                    )
                }

                ForEach(DallasTeam.allCases) { team in
                    if let realtimeScore = scoreService.activeGames[team] {
                        let delayedScore = delayQueue.delayedScores[team]
                        GameScoreCard(
                            team: team,
                            displayScore: delayedScore ?? realtimeScore,
                            isDelayed: delayedScore != nil
                        )
                    }
                }

                if let error = scoreService.lastError {
                    Section("Status") {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .navigationTitle("Today's Games")
            .refreshable {
                isLoading = true
                await scoreService.fetchAllScores()
                isLoading = false
            }
            .onAppear {
                if scoreService.activeGames.isEmpty {
                    isLoading = true
                    Task {
                        await scoreService.fetchAllScores()
                        isLoading = false
                    }
                }
            }
        }
    }
}

struct GameScoreCard: View {
    let team: DallasTeam
    let displayScore: GameScore
    let isDelayed: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Header: sport + status
            HStack {
                Text(team.sport)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(hex: team.primaryColor).opacity(0.2))
                    .clipShape(Capsule())

                Spacer()

                if isDelayed {
                    Label("Delayed", systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                StatusBadge(state: displayScore.state, detail: displayScore.clockDisplay)
            }

            // Score
            HStack {
                TeamScoreColumn(
                    abbreviation: displayScore.awayTeam,
                    fullName: displayScore.awayTeamFull,
                    score: displayScore.awayScore,
                    isHome: false
                )

                Spacer()

                if displayScore.isLive {
                    Text(displayScore.statusDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                TeamScoreColumn(
                    abbreviation: displayScore.homeTeam,
                    fullName: displayScore.homeTeamFull,
                    score: displayScore.homeScore,
                    isHome: true
                )
            }
        }
        .padding(.vertical, 8)
    }
}

struct TeamScoreColumn: View {
    let abbreviation: String
    let fullName: String
    let score: Int
    let isHome: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(abbreviation)
                .font(.title2.bold())
            Text("\(score)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
            if isHome {
                Text("HOME")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 80)
    }
}

struct StatusBadge: View {
    let state: String
    let detail: String

    var body: some View {
        HStack(spacing: 4) {
            if state == "in" {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text("LIVE")
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            } else if state == "post" {
                Text("FINAL")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            } else {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Color from hex

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
