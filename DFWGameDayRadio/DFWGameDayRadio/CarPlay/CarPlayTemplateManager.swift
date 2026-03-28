import CarPlay
import MediaPlayer
import UIKit

class CarPlayTemplateManager {
    weak var interfaceController: CPInterfaceController?

    private let coordinator = GameCoordinator.shared
    private var logoCache: [String: UIImage] = [:]
    private var scoreUpdateTimer: Timer?
    private var lastMetadataContent: String = ""

    func buildRootTemplate() -> CPTabBarTemplate {
        let stationsTab = buildStationsTemplate()
        stationsTab.tabImage = UIImage(systemName: "radio")

        // Configure Now Playing template with custom buttons
        configureNowPlaying()

        let tabBar = CPTabBarTemplate(templates: [stationsTab])
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

            // Letter-initial placeholder image with team color
            let placeholderImage = renderStationPlaceholder(station: station)

            let item = CPListItem(
                text: station.displayName,
                detailText: teamsText,
                image: placeholderImage
            )

            item.handler = { [weak self] _, completion in
                self?.coordinator.playAndTrack(station: station)
                self?.startScoreMetadataUpdates()
                completion()
            }

            // Show animated equalizer bars on active station
            if coordinator.currentStation == station {
                item.isPlaying = true
            }

            return item
        }

        let section = CPListSection(items: items, header: "Dallas Sports Radio", sectionIndexTitle: nil)
        let template = CPListTemplate(title: "Stations", sections: [section])
        template.tabTitle = "Stations"

        // Pre-fetch real team logos asynchronously
        prefetchLogos(for: items)

        return template
    }

    // MARK: - Now Playing Configuration

    private func configureNowPlaying() {
        let nowPlaying = CPNowPlayingTemplate.shared

        // Custom delay buttons with descriptive images
        let delayMinusImage = renderDelayButtonImage(text: "-5s")
        let delayPlusImage = renderDelayButtonImage(text: "+5s")

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
        // Safety-net timer at 10s; actual updates are change-driven
        scoreUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
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
                var line = score.scoreLine
                if score.isLive {
                    line += " | \(score.statusDetail)"
                }
                // Append situation micro-summary if available
                if let situation = score.situation {
                    line += " · \(situation.microSummary)"
                }
                scoreParts.append(line)
            }
        }

        let newContent = scoreParts.joined(separator: " ")

        // Only update if content actually changed
        guard !newContent.isEmpty, newContent != lastMetadataContent else { return }
        lastMetadataContent = newContent

        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPMediaItemPropertyArtist] = newContent
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
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
                        let size = CGSize(width: LayoutConstants.carPlayLogoSize, height: LayoutConstants.carPlayLogoSize)
                        let renderer = UIGraphicsImageRenderer(size: size)
                        let scaled = renderer.image { ctx in
                            // Draw on square canvas for CarPlay
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

    // MARK: - Image Rendering Helpers

    /// Renders a 44x44 placeholder image with team color background and station initial letter.
    private func renderStationPlaceholder(station: RadioStation) -> UIImage {
        let size = CGSize(width: LayoutConstants.carPlayLogoSize, height: LayoutConstants.carPlayLogoSize)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            // Team color background
            let hex = station.teams.first?.primaryColor ?? "#333333"
            let color = UIColor(hex: hex)
            color.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 10).fill()

            // Station initial letter
            let initial = String(station.displayName.filter(\.isLetter).prefix(1))
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: UIColor.white
            ]
            let textSize = initial.size(withAttributes: attributes)
            let textOrigin = CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            )
            initial.draw(at: textOrigin, withAttributes: attributes)
        }
    }

    /// Renders a 20x20 delay button image with text label.
    private func renderDelayButtonImage(text: String) -> UIImage {
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 10),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let textOrigin = CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            )
            text.draw(at: textOrigin, withAttributes: attributes)
        }
    }
}

// MARK: - UIColor hex helper

private extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255.0
        let g = CGFloat((int >> 8) & 0xFF) / 255.0
        let b = CGFloat(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
