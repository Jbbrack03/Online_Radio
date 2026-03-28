import SwiftUI

struct StationPickerView: View {
    @State private var coordinator = GameCoordinator.shared
    @State private var showNowPlaying = false

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
                        Haptics.medium()
                        coordinator.playAndTrack(station: station)
                    }
                }
            }
            .navigationTitle("DFW GameDay Radio")
            .overlay(alignment: .bottom) {
                if coordinator.currentStation != nil {
                    NowPlayingBar(showNowPlaying: $showNowPlaying)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.smooth, value: coordinator.currentStation != nil)
            .sheet(isPresented: $showNowPlaying) {
                NowPlayingView()
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

    @ScaledMetric(relativeTo: .body) private var logoSize: CGFloat = 36

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md) {
                // Team logos — side by side with overlap
                HStack(spacing: -8) {
                    ForEach(station.teams) { team in
                        AsyncImage(url: team.logoURL) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: logoSize, height: logoSize)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(Color(.systemBackground), lineWidth: station.teams.count > 1 ? 2 : 0)
                        )
                    }
                }
                .frame(minWidth: 52)

                VStack(alignment: .leading, spacing: Spacing.xs) {
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

                // Status indicator
                if isBuffering {
                    ProgressView()
                } else if isPlaying {
                    nowPlayingPill
                } else if isActive {
                    Image(systemName: "speaker.slash")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(station.displayName), \(station.teams.map(\.shortName).joined(separator: " and "))\(isPlaying ? ", now playing" : isBuffering ? ", loading" : "")")
        .accessibilityAddTraits(.isButton)
        .listRowBackground(isActive ? stationGradient : nil)
    }

    private var nowPlayingPill: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "waveform")
                .symbolEffect(.variableColor.iterative)
        }
        .font(.caption.bold())
        .foregroundStyle(Color(hex: station.teams.first?.primaryColor ?? "#007AFF"))
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(Color(hex: station.teams.first?.primaryColor ?? "#007AFF").opacity(0.15))
        .clipShape(Capsule())
    }

    private var stationGradient: some View {
        let color = Color(hex: station.teams.first?.primaryColor ?? "#333333")
        return LinearGradient(
            colors: [color.opacity(0.20), color.opacity(0.08)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

struct NowPlayingBar: View {
    @State private var coordinator = GameCoordinator.shared
    @Binding var showNowPlaying: Bool
    @ScaledMetric private var miniLogoSize: CGFloat = 36

    var body: some View {
        if let station = coordinator.currentStation {
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: Spacing.md) {
                    // Team accent bar
                    if let team = station.teams.first {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color(hex: team.secondaryColor))
                            .frame(width: 3, height: 40)
                    }

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

                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(station.displayName)
                            .font(.subheadline.bold())
                        if let team = station.teams.first,
                           let score = coordinator.delayedScores[team] {
                            Text(score.scoreLine)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText())
                        }
                    }

                    Spacer()

                    // Expand chevron
                    Image(systemName: "chevron.up")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

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
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .background(.ultraThinMaterial)
                .contentShape(Rectangle())
                .onTapGesture {
                    showNowPlaying = true
                }
            }
        }
    }
}
