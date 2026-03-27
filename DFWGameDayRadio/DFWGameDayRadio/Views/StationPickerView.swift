import SwiftUI

struct StationPickerView: View {
    @State private var audioManager = AudioStreamManager.shared
    @State private var scoreService = ESPNScoreService.shared
    @State private var delayQueue = ScoreDelayQueue.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(RadioStation.allCases) { station in
                    StationRow(
                        station: station,
                        isActive: audioManager.currentStation == station,
                        isPlaying: audioManager.currentStation == station && audioManager.isPlaying,
                        isBuffering: audioManager.currentStation == station && audioManager.isBuffering
                    ) {
                        handleStationTap(station)
                    }
                }
            }
            .navigationTitle("DFW GameDay Radio")
            .overlay {
                if audioManager.currentStation != nil {
                    VStack {
                        Spacer()
                        NowPlayingBar()
                    }
                }
            }
        }
    }

    private func handleStationTap(_ station: RadioStation) {
        if audioManager.currentStation == station {
            audioManager.togglePlayPause()
        } else {
            audioManager.play(station: station)
            startTracking(station: station)
        }
    }

    private func startTracking(station: RadioStation) {
        let teams = station.teams
        scoreService.startPolling(for: teams)
        delayQueue.startProcessing()

        // Start live activities for live games after a brief delay for ESPN to respond
        Task {
            try? await Task.sleep(for: .seconds(3))
            for team in teams {
                if let score = scoreService.activeGames[team], score.isLive {
                    LiveActivityManager.shared.startActivity(for: team, score: score, station: station)
                }
            }
        }
    }
}

struct StationRow: View {
    let station: RadioStation
    let isActive: Bool
    let isPlaying: Bool
    let isBuffering: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.title2)
                    .foregroundStyle(isActive ? .blue : .secondary)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(station.displayName)
                        .font(.headline)
                    Text(station.callSign)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(station.teams.map(\.shortName).joined(separator: " / "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isBuffering {
                    ProgressView()
                } else if isPlaying {
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundStyle(.blue)
                        .symbolEffect(.variableColor.iterative)
                } else if isActive {
                    Image(systemName: "speaker.slash")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct NowPlayingBar: View {
    @State private var audioManager = AudioStreamManager.shared
    @State private var delayQueue = ScoreDelayQueue.shared

    var body: some View {
        if let station = audioManager.currentStation {
            VStack(spacing: 0) {
                Divider()
                HStack {
                    VStack(alignment: .leading) {
                        Text(station.displayName)
                            .font(.subheadline.bold())
                        if let team = station.teams.first,
                           let score = delayQueue.delayedScores[team] {
                            Text(score.scoreLine)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    Button(action: { audioManager.togglePlayPause() }) {
                        Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                    }

                    Button(action: {
                        audioManager.stop()
                        ScoreDelayQueue.shared.stopProcessing()
                        ESPNScoreService.shared.stopPolling()
                        LiveActivityManager.shared.endAllActivities()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
}
