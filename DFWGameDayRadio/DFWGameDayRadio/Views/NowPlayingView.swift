import SwiftUI

struct NowPlayingView: View {
    @State private var coordinator = GameCoordinator.shared
    @State private var delayQueue = ScoreDelayQueue.shared
    @State private var latencyEstimator = StreamLatencyEstimator.shared
    @State private var offsetValue: Double = ScoreDelayQueue.shared.userOffset

    @Environment(\.dismiss) private var dismiss

    private var station: RadioStation? { coordinator.currentStation }
    private var primaryTeam: DallasTeam? { station?.teams.first }

    private var teamColor: Color {
        guard let team = primaryTeam else { return .accentColor }
        return Color(hex: team.primaryColor)
    }

    private var teamSecondaryColor: Color {
        guard let team = primaryTeam else { return .secondary }
        return Color(hex: team.secondaryColor)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Large artwork
                    artworkSection

                    // Station info
                    stationInfo

                    // Score display
                    if let team = primaryTeam,
                       let score = coordinator.delayedScores[team] {
                        scoreSection(score: score)
                    }

                    // Playback controls
                    playbackControls

                    // Delay adjustment
                    delaySection

                    // Stream info
                    streamInfo
                }
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.xxl)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Artwork

    private var artworkSection: some View {
        ZStack {
            // Radial gradient background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [teamColor.opacity(0.3), teamSecondaryColor.opacity(0.1), .clear],
                        center: .center,
                        startRadius: 40,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)

            // Team logo
            if let team = primaryTeam {
                AsyncImage(url: team.logoURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Image(systemName: "radio")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 160, height: 160)
            }
        }
        .padding(.top, Spacing.lg)
    }

    // MARK: - Station Info

    private var stationInfo: some View {
        VStack(spacing: Spacing.xs) {
            if let station {
                Text(station.displayName)
                    .font(.title2.bold())
                Text(station.teams.map(\.shortName).joined(separator: " / "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Score

    private func scoreSection(score: GameScore) -> some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.xl) {
                VStack(spacing: Spacing.xs) {
                    Text(score.awayTeam)
                        .font(.headline.bold())
                    Text("\(score.awayScore)")
                        .font(.largeTitle.bold())
                        .fontDesign(.rounded)
                        .contentTransition(.numericText())
                }

                VStack(spacing: Spacing.xs) {
                    if score.isLive {
                        HStack(spacing: Spacing.xs) {
                            Circle()
                                .fill(.red)
                                .frame(width: 8, height: 8)
                                .symbolEffect(.pulse.byLayer)
                            Text("LIVE")
                                .font(.caption.bold())
                                .foregroundStyle(.red)
                        }
                    }
                    Text(score.statusDetail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: Spacing.xs) {
                    Text(score.homeTeam)
                        .font(.headline.bold())
                    Text("\(score.homeScore)")
                        .font(.largeTitle.bold())
                        .fontDesign(.rounded)
                        .contentTransition(.numericText())
                }
            }

            // Situation view (full, not compact)
            if let situation = score.situation {
                Divider()
                SituationView(
                    situation: situation,
                    homeTeam: score.homeTeam,
                    awayTeam: score.awayTeam
                )
            }
        }
        .padding(Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: Spacing.xxl) {
            Button(action: {
                Haptics.light()
                coordinator.stopPlayback()
                dismiss()
            }) {
                Image(systemName: "stop.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Stop")

            Button(action: {
                Haptics.medium()
                withAnimation(.snappy) {
                    coordinator.togglePlayPause()
                }
            }) {
                Image(systemName: coordinator.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(teamColor)
                    .clipShape(Circle())
            }
            .accessibilityLabel(coordinator.isPlaying ? "Pause" : "Play")

            // Effective delay indicator
            VStack(spacing: Spacing.xxs) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let station {
                    Text(formatDelay(latencyEstimator.effectiveDelay(for: station, userOffset: delayQueue.userOffset)))
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 44, height: 44)
        }
    }

    // MARK: - Delay Adjustment

    private var delaySection: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("Fine-Tune Offset")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatOffset(offsetValue))
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(offsetValue != 0 ? .orange : .secondary)
            }

            Slider(value: $offsetValue, in: -15...15, step: 1) {
                Text("Delay offset")
            } minimumValueLabel: {
                Text("-15s").font(.caption2)
            } maximumValueLabel: {
                Text("+15s").font(.caption2)
            }
            .tint(teamColor)
            .onChange(of: offsetValue) { _, newValue in
                Haptics.selection()
                delayQueue.userOffset = newValue
            }

            Text("Adjust to sync scores with your radio broadcast")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }

    // MARK: - Stream Info

    private var streamInfo: some View {
        Group {
            if let station {
                HStack {
                    if let source = latencyEstimator.estimateSource[station] {
                        Label("Latency: \(source.rawValue)", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    Spacer()
                    if let latency = latencyEstimator.estimatedLatency[station] {
                        Text("~\(Int(latency))s stream delay")
                    }
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Helpers

    private func formatDelay(_ delay: TimeInterval) -> String {
        let seconds = Int(delay)
        return "\(seconds)s"
    }

    private func formatOffset(_ value: Double) -> String {
        let intValue = Int(value)
        if intValue > 0 { return "+\(intValue)s" }
        if intValue < 0 { return "\(intValue)s" }
        return "0s"
    }
}
