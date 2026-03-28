import SwiftUI

struct GameListView: View {
    @State private var coordinator = GameCoordinator.shared
    @State private var isLoading = false
    @State private var scoreService = ESPNScoreService.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Spacing.md) {
                    ForEach(DallasTeam.allCases) { team in
                        let delayedScore = coordinator.delayedScores[team]
                        let realtimeScore = coordinator.activeGames[team] ?? scoreService.activeGames[team]

                        if let displayScore = delayedScore ?? realtimeScore {
                            GameScoreCard(
                                team: team,
                                displayScore: displayScore,
                                isDelayed: delayedScore != nil
                            )
                        }
                    }

                    if !coordinator.activeErrors.isEmpty {
                        ForEach(coordinator.activeErrors, id: \.self) { error in
                            Label(error, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .padding(.horizontal, Spacing.lg)
                        }
                    } else if let error = scoreService.lastError {
                        Label(error, systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, Spacing.lg)
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }
            .overlay {
                if isLoading && !hasAnyGames {
                    ProgressView("Loading scores...")
                } else if !hasAnyGames && !isLoading {
                    ContentUnavailableView(
                        "No Games Today",
                        systemImage: "sportscourt",
                        description: Text("No Dallas team games found on today's schedule.")
                    )
                }
            }
            .navigationTitle("Today's Games")
            .refreshable {
                isLoading = true
                await scoreService.fetchAllScores()
                isLoading = false
            }
            .onAppear {
                guard !isLoading && !hasAnyGames else { return }
                isLoading = true
                Task {
                    await scoreService.fetchAllScores()
                    isLoading = false
                }
            }
        }
    }

    private var hasAnyGames: Bool {
        !coordinator.activeGames.isEmpty || !scoreService.activeGames.isEmpty
    }
}

struct GameScoreCard: View {
    let team: DallasTeam
    let displayScore: GameScore
    let isDelayed: Bool

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Header: sport badge + status
            HStack {
                Text(team.sport)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(Color(hex: team.primaryColor))
                    .clipShape(Capsule())

                Spacer()

                if isDelayed {
                    Label("Delayed", systemImage: "clock")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }

                StatusBadge(state: displayScore.state, detail: displayScore.clockDisplay)
            }

            // Score row
            HStack {
                TeamScoreColumn(
                    team: team,
                    abbreviation: displayScore.awayTeam,
                    fullName: displayScore.awayTeamFull,
                    score: displayScore.awayScore,
                    isHome: false
                )

                Spacer()

                if displayScore.isLive {
                    Text(displayScore.statusDetail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                TeamScoreColumn(
                    team: team,
                    abbreviation: displayScore.homeTeam,
                    fullName: displayScore.homeTeamFull,
                    score: displayScore.homeScore,
                    isHome: true
                )
            }

            // Sport-specific situation
            if let situation = displayScore.situation {
                Divider()
                SituationView(
                    situation: situation,
                    homeTeam: displayScore.homeTeam,
                    awayTeam: displayScore.awayTeam
                )
            }
        }
        .padding(Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(alignment: .leading) {
                    // Team accent bar on left edge
                    UnevenRoundedRectangle(
                        topLeadingRadius: CornerRadius.card,
                        bottomLeadingRadius: CornerRadius.card,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                    .fill(Color(hex: team.secondaryColor))
                    .frame(width: 3)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: team.primaryColor).opacity(0.12), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .clipShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
        .accessibilityElement(children: .contain)
    }
}

struct TeamScoreColumn: View {
    let team: DallasTeam
    let abbreviation: String
    let fullName: String
    let score: Int
    let isHome: Bool

    @ScaledMetric(relativeTo: .title) private var logoSize: CGFloat = 48

    var body: some View {
        VStack(spacing: Spacing.xs) {
            AsyncImage(url: logoURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Text(abbreviation)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
            .frame(width: logoSize, height: logoSize)
            .accessibilityHidden(true)

            Text(abbreviation)
                .font(.headline.bold())
            Text("\(score)")
                .font(.largeTitle.bold())
                .fontDesign(.rounded)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
            if isHome {
                Text("HOME")
                    .font(.caption2)
                    .foregroundStyle(Color(hex: team.secondaryColor))
            }
        }
        .frame(minWidth: 80)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(fullName), score \(score)\(isHome ? ", home team" : "")")
    }

    private var logoURL: URL? {
        ESPNImages.teamLogoURL(
            league: team.espnLeague,
            abbreviation: abbreviation.lowercased(),
            size: 96
        )
    }
}

struct StatusBadge: View {
    let state: String
    let detail: String

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if state == "in" {
                Image(systemName: "circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.red)
                    .symbolEffect(.pulse.byLayer)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(state == "in" ? "Game is live" : state == "post" ? "Game is final" : detail)
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
