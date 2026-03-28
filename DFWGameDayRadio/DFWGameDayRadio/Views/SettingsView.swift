import SwiftUI

struct SettingsView: View {
    @State private var delayQueue = ScoreDelayQueue.shared
    @State private var latencyEstimator = StreamLatencyEstimator.shared
    @State private var offsetValue: Double = ScoreDelayQueue.shared.userOffset
    @State private var coordinator = GameCoordinator.shared

    var body: some View {
        NavigationStack {
            Form {
                broadcastSyncSection
                stationLatencySection
                stationsSection
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear {
                offsetValue = delayQueue.userOffset
            }
        }
    }

    // MARK: - Broadcast Sync

    private var broadcastSyncSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                // Current effective delay
                HStack {
                    Text("Effective Delay")
                        .font(.headline)
                    Spacer()
                    Text("\(Int(delayQueue.effectiveDelaySeconds))s")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(.blue)
                }

                // Fine-tune slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Fine-Tune Offset")
                            .font(.subheadline)
                        Spacer()
                        Text(offsetLabel)
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(offsetValue == 0 ? Color.secondary : Color.orange)
                    }

                    Slider(value: $offsetValue, in: -15...15, step: 1) {
                        Text("Offset")
                    } minimumValueLabel: {
                        Text("-15")
                            .font(.caption2)
                    } maximumValueLabel: {
                        Text("+15")
                            .font(.caption2)
                    }
                    .accessibilityLabel("Fine-tune delay offset")
                    .accessibilityValue("\(Int(offsetValue)) seconds")
                    .sensoryFeedback(.selection, trigger: offsetValue)
                    .onChange(of: offsetValue) { _, newValue in
                        delayQueue.userOffset = newValue
                    }
                }

                Text("The app auto-estimates stream delay per station. Use the offset slider to fine-tune if scores appear too early or late.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        } header: {
            Text("Broadcast Sync")
        }
    }

    private var offsetLabel: String {
        if offsetValue == 0 {
            return "0s"
        } else if offsetValue > 0 {
            return "+\(Int(offsetValue))s"
        } else {
            return "\(Int(offsetValue))s"
        }
    }

    // MARK: - Per-Station Latency

    private var stationLatencySection: some View {
        Section {
            ForEach(RadioStation.allCases) { station in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(station.displayName)
                            .font(.subheadline.bold())
                        if let source = latencyEstimator.estimateSource[station] {
                            Text(source.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    if let latency = latencyEstimator.estimatedLatency[station] {
                        Text("~\(Int(latency))s")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    if latencyEstimator.isProbing && delayQueue.currentStation == station {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            }
        } header: {
            Text("Estimated Stream Delay")
        } footer: {
            Text("Auto-detected latency for each station's internet stream behind the live broadcast.")
        }
    }

    // MARK: - Stations

    private var stationsSection: some View {
        Section {
            ForEach(RadioStation.allCases) { station in
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .accessibilityHidden(true)
                    VStack(alignment: .leading) {
                        Text(station.displayName)
                            .font(.subheadline.bold())
                        Text(station.teams.map(\.shortName).joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(station.displayName), \(station.callSign), teams: \(station.teams.map(\.shortName).joined(separator: " and "))")
            }
        } header: {
            Text("Stations")
        } footer: {
            Text("Station-to-team mappings for automatic score tracking.")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            LabeledContent("Score Polling", value: "Every 10s")
            LabeledContent("NFL Source", value: "ESPN")
            LabeledContent("MLB Source", value: "MLB Stats API")
            LabeledContent("NBA Source", value: "NBA CDN")
            LabeledContent("NHL Source", value: "NHL API")
            LabeledContent("Live Activity", value: "Delayed scores")
        } header: {
            Text("About")
        } footer: {
            Text("Scores are fetched from league-native APIs and held for the estimated delay before displaying on Live Activities and in-app.")
        }
    }
}
