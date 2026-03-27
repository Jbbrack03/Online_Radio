import CarPlay
import UIKit

class CarPlayTemplateManager {
    weak var interfaceController: CPInterfaceController?

    private let audioManager = AudioStreamManager.shared

    func buildRootTemplate() -> CPTabBarTemplate {
        let stationsTab = buildStationsTemplate()
        let nowPlayingTab = CPNowPlayingTemplate.shared

        stationsTab.tabImage = UIImage(systemName: "radio")
        nowPlayingTab.tabImage = UIImage(systemName: "music.note")

        let tabBar = CPTabBarTemplate(templates: [stationsTab, nowPlayingTab])
        return tabBar
    }

    private func buildStationsTemplate() -> CPListTemplate {
        let items = RadioStation.allCases.map { station -> CPListItem in
            let teamsText = station.teams.map(\.shortName).joined(separator: ", ")
            let item = CPListItem(
                text: station.displayName,
                detailText: teamsText,
                image: UIImage(systemName: "antenna.radiowaves.left.and.right")
            )

            item.handler = { [weak self] _, completion in
                self?.audioManager.play(station: station)
                self?.startScoreTracking(for: station)
                completion()

                // Navigate to Now Playing
                if let controller = self?.interfaceController {
                    controller.pushTemplate(CPNowPlayingTemplate.shared, animated: true, completion: nil)
                }
            }

            // Show "Now Playing" indicator
            if audioManager.currentStation == station {
                item.isPlaying = true
            }

            return item
        }

        let section = CPListSection(items: items, header: "Dallas Sports Radio", sectionIndexTitle: nil)
        let template = CPListTemplate(title: "Stations", sections: [section])
        template.tabTitle = "Stations"
        return template
    }

    private func startScoreTracking(for station: RadioStation) {
        let teams = station.teams
        ESPNScoreService.shared.startPolling(for: teams)
        ScoreDelayQueue.shared.startProcessing()

        // Start live activities for any active games
        Task {
            // Give ESPN a moment to fetch
            try? await Task.sleep(for: .seconds(2))
            for team in teams {
                if let score = ESPNScoreService.shared.activeGames[team], score.isLive {
                    LiveActivityManager.shared.startActivity(for: team, score: score, station: station)
                }
            }
        }
    }
}
