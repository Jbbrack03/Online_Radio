import SwiftUI

struct StationPickerView: View {
    @State private var coordinator = GameCoordinator.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(RadioStation.allCases) { station in
                    StationRow(
                        station: station,
                        isActive: coordinator.currentStation == station,
                        isPlaying: coordinator.currentStation == station && coordinator.isPlaying,
                        isBuffering: coordinator.currentStation == station && coordinator.isBuffering
                    ) {
                        coordinator.playAndTrack(station: station)
                    }
                }
            }
            .navigationTitle("DFW GameDay Radio")
            .overlay(alignment: .bottom) {
                if coordinator.currentStation != nil {
                    NowPlayingBar()
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
            HStack(spacing: 12) {
                // Team logos
                teamLogos
                    .frame(width: 52)

                VStack(alignment: .leading, spacing: 4) {
                    Text(station.displayName)
                        .font(.title3.bold())
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
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isActive ? stationGradient : nil
        )
    }

    private var teamLogos: some View {
        ZStack {
            ForEach(Array(station.teams.enumerated()), id: \.element.id) { index, team in
                AsyncImage(url: team.logoURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 36, height: 36)
                .offset(x: station.teams.count > 1 ? CGFloat(index * 16 - 8) : 0)
            }
        }
    }

    private var stationGradient: some View {
        let color = Color(hex: station.teams.first?.primaryColor ?? "#333333")
        return LinearGradient(
            colors: [color.opacity(0.15), color.opacity(0.05)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct NowPlayingBar: View {
    @State private var coordinator = GameCoordinator.shared

    var body: some View {
        if let station = coordinator.currentStation {
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    // Team logo
                    if let team = station.teams.first {
                        AsyncImage(url: team.logoURL) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Image(systemName: "radio")
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 32, height: 32)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(station.displayName)
                            .font(.subheadline.bold())
                        if let team = station.teams.first,
                           let score = coordinator.delayedScores[team] {
                            Text(score.scoreLine)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText())
                        }
                    }

                    Spacer()

                    Button(action: { coordinator.togglePlayPause() }) {
                        Image(systemName: coordinator.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                    }

                    Button(action: { coordinator.stopPlayback() }) {
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
