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

    @ScaledMetric(relativeTo: .body) private var logoAreaWidth: CGFloat = 52
    @ScaledMetric(relativeTo: .body) private var logoSize: CGFloat = 36

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Team logos
                teamLogos
                    .frame(width: logoAreaWidth)

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(station.displayName), \(station.teams.map(\.shortName).joined(separator: " and "))\(isPlaying ? ", now playing" : isBuffering ? ", loading" : "")")
        .accessibilityAddTraits(.isButton)
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
                .frame(width: logoSize, height: logoSize)
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
    @ScaledMetric private var miniLogoSize: CGFloat = 32

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
                        .frame(width: miniLogoSize, height: miniLogoSize)
                        .accessibilityHidden(true)
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
                    .accessibilityLabel(coordinator.isPlaying ? "Pause" : "Play")

                    Button(action: { coordinator.stopPlayback() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Stop playback")
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
}
