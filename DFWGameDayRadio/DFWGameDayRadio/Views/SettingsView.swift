import SwiftUI

struct SettingsView: View {
    @State private var delayQueue = ScoreDelayQueue.shared
    @State private var delayValue: Double = ScoreDelayQueue.shared.delaySeconds

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Score Delay")
                                .font(.headline)
                            Spacer()
                            Text("\(Int(delayValue))s")
                                .font(.title2.bold().monospacedDigit())
                                .foregroundStyle(.blue)
                        }

                        Slider(value: $delayValue, in: 0...60, step: 1) {
                            Text("Delay")
                        } minimumValueLabel: {
                            Text("0s")
                                .font(.caption)
                        } maximumValueLabel: {
                            Text("60s")
                                .font(.caption)
                        }
                        .onChange(of: delayValue) { _, newValue in
                            delayQueue.delaySeconds = newValue
                        }

                        Text("Delays score updates to match your radio broadcast. Typical radio delay is 10-20 seconds behind real-time.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Broadcast Sync")
                }

                Section {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        VStack(alignment: .leading) {
                            Text("105.3 The Fan")
                                .font(.subheadline.bold())
                            Text("Cowboys, Rangers")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        VStack(alignment: .leading) {
                            Text("97.1 The Eagle")
                                .font(.subheadline.bold())
                            Text("Mavericks")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                        VStack(alignment: .leading) {
                            Text("96.7 The Ticket")
                                .font(.subheadline.bold())
                            Text("Stars")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Stations")
                } footer: {
                    Text("Station-to-team mappings for automatic score tracking.")
                }

                Section {
                    LabeledContent("ESPN Polling", value: "Every 10s")
                    LabeledContent("Score Source", value: "ESPN Scoreboard API")
                    LabeledContent("Live Activity", value: "Delayed scores")
                } header: {
                    Text("About")
                } footer: {
                    Text("Scores are fetched from ESPN and held for the configured delay before displaying on the Live Activity and in-app.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
