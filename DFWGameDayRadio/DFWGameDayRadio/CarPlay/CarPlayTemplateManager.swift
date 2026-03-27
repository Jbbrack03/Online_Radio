import CarPlay
import MediaPlayer
import UIKit

class CarPlayTemplateManager {
    weak var interfaceController: CPInterfaceController?

    private let coordinator = GameCoordinator.shared
    private var logoCache: [String: UIImage] = [:]
    private var scoreUpdateTimer: Timer?

    func buildRootTemplate() -> CPTabBarTemplate {
        let stationsTab = buildStationsTemplate()
        let nowPlayingTab = CPNowPlayingTemplate.shared

        stationsTab.tabImage = UIImage(systemName: "radio")
        nowPlayingTab.tabImage = UIImage(systemName: "music.note")

        // Configure Now Playing template with custom buttons
        configureNowPlaying()

        let tabBar = CPTabBarTemplate(templates: [stationsTab, nowPlayingTab])
        return tabBar
    }

    func tearDown() {
        scoreUpdateTimer?.invalidate()
        scoreUpdateTimer = nil
    }

    // MARK: - Stations List

    private func buildStationsTemplate() -> CPListTemplate {
        let items = RadioStation.allCases.map { station -> CPListItem in
            let teamsText = station.teams.map(\.shortName).joined(separator: ", ")
            let item = CPListItem(
                text: station.displayName,
                detailText: teamsText,
                image: UIImage(systemName: "antenna.radiowaves.left.and.right")
            )

            item.handler = { [weak self] _, completion in
                self?.coordinator.playAndTrack(station: station)
                self?.startScoreMetadataUpdates()
                completion()

                // Switch to Now Playing tab (don't push — it's already in the tab bar)
                if let tabBar = self?.interfaceController?.rootTemplate as? CPTabBarTemplate {
                    let nowPlayingIndex = tabBar.templates.firstIndex(where: { $0 is CPNowPlayingTemplate })
                    if let index = nowPlayingIndex {
                        tabBar.selectTemplate(at: index)
                    }
                }
            }

            // Show "Now Playing" indicator
            if coordinator.currentStation == station {
                item.isPlaying = true
            }

            return item
        }

        let section = CPListSection(items: items, header: "Dallas Sports Radio", sectionIndexTitle: nil)
        let template = CPListTemplate(title: "Stations", sections: [section])
        template.tabTitle = "Stations"

        // Pre-fetch team logos asynchronously and update list items
        prefetchLogos(for: items)

        return template
    }

    // MARK: - Now Playing Configuration

    private func configureNowPlaying() {
        let nowPlaying = CPNowPlayingTemplate.shared

        // Custom buttons: delay adjustment
        let delayMinusImage = UIImage(systemName: "minus.circle") ?? UIImage()
        let delayPlusImage = UIImage(systemName: "plus.circle") ?? UIImage()

        let delayMinus = CPNowPlayingImageButton(image: delayMinusImage) { _ in
            let queue = ScoreDelayQueue.shared
            queue.userOffset = max(-15, queue.userOffset - 5)
        }

        let delayPlus = CPNowPlayingImageButton(image: delayPlusImage) { _ in
            let queue = ScoreDelayQueue.shared
            queue.userOffset = min(15, queue.userOffset + 5)
        }

        nowPlaying.updateNowPlayingButtons([delayMinus, delayPlus])
    }

    // MARK: - Score Metadata Updates

    /// Periodically update MPNowPlayingInfoCenter with current score for display on CarPlay.
    func startScoreMetadataUpdates() {
        scoreUpdateTimer?.invalidate()
        scoreUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateNowPlayingWithScore()
        }
        // Also update immediately
        updateNowPlayingWithScore()
    }

    private func updateNowPlayingWithScore() {
        guard let station = coordinator.currentStation else { return }

        var scoreParts: [String] = []
        for team in station.teams {
            if let score = coordinator.delayedScores[team] {
                scoreParts.append(score.scoreLine)
                if score.isLive {
                    scoreParts.append("| \(score.statusDetail)")
                }
            }
        }

        if !scoreParts.isEmpty {
            var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
            info[MPMediaItemPropertyArtist] = scoreParts.joined(separator: " ")
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    // MARK: - Logo Prefetch

    private func prefetchLogos(for items: [CPListItem]) {
        let stations = RadioStation.allCases
        for (index, station) in stations.enumerated() {
            guard let team = station.teams.first,
                  let url = team.logoURL else { continue }

            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let image = UIImage(data: data) {
                        // Scale to appropriate CarPlay size
                        let size = CGSize(width: LayoutConstants.carPlayLogoSize, height: LayoutConstants.carPlayLogoSize)
                        let renderer = UIGraphicsImageRenderer(size: size)
                        let scaled = renderer.image { _ in
                            image.draw(in: CGRect(origin: .zero, size: size))
                        }
                        await MainActor.run {
                            if index < items.count {
                                items[index].setImage(scaled)
                            }
                        }
                    }
                } catch {
                    print("[CarPlay] Logo fetch failed for \(station.displayName): \(error.localizedDescription)")
                }
            }
        }
    }
}
