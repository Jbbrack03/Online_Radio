import Foundation

@Observable
class ScoreDelayQueue {
    static let shared = ScoreDelayQueue()

    var delayedScores: [DallasTeam: GameScore] = [:]
    var delaySeconds: TimeInterval {
        get { UserDefaults.standard.double(forKey: UserDefaultsKeys.scoreDelay).clamped(to: 0...60) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.scoreDelay) }
    }

    private var queues: [DallasTeam: [DelayedScoreEvent]] = [:]
    private var timer: Timer?

    private init() {
        // Set default delay if not configured
        if UserDefaults.standard.object(forKey: UserDefaultsKeys.scoreDelay) == nil {
            UserDefaults.standard.set(15.0, forKey: UserDefaultsKeys.scoreDelay)
        }
    }

    func enqueue(_ score: GameScore, for team: DallasTeam) {
        let event = DelayedScoreEvent(timestamp: Date(), score: score)
        if queues[team] == nil {
            queues[team] = []
        }

        // Only enqueue if score actually changed
        if let last = queues[team]?.last, last.score == score {
            return
        }
        if let current = delayedScores[team], current == score, queues[team]?.isEmpty ?? true {
            return
        }

        queues[team]?.append(event)
    }

    func startProcessing() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.processQueues()
        }
    }

    func stopProcessing() {
        timer?.invalidate()
        timer = nil
    }

    func clear() {
        queues.removeAll()
        delayedScores.removeAll()
    }

    private func processQueues() {
        let now = Date()
        let delay = delaySeconds

        for team in queues.keys {
            while let first = queues[team]?.first,
                  now.timeIntervalSince(first.timestamp) >= delay {
                delayedScores[team] = first.score
                queues[team]?.removeFirst()

                // Notify Live Activity manager
                LiveActivityManager.shared.updateScore(first.score, for: team)
            }
        }
    }
}

// MARK: - Comparable clamping helper

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
