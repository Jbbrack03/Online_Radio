import Foundation

@Observable
class ScoreDelayQueue {
    static let shared = ScoreDelayQueue()

    var delayedScores: [DallasTeam: GameScore] = [:]
    var currentStation: RadioStation?

    /// User's fine-tune offset (can be negative or positive).
    var userOffset: TimeInterval {
        get { UserDefaults.standard.double(forKey: UserDefaultsKeys.userDelayOffset) }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKeys.userDelayOffset) }
    }

    /// The effective delay being applied right now (computed from estimator + user offset).
    var effectiveDelaySeconds: TimeInterval {
        guard let station = currentStation else {
            return legacyDelaySeconds
        }
        return StreamLatencyEstimator.shared.effectiveDelay(for: station, userOffset: userOffset)
    }

    /// Legacy manual delay for backward compatibility (used when no station is set).
    private var legacyDelaySeconds: TimeInterval {
        UserDefaults.standard.double(forKey: UserDefaultsKeys.scoreDelay).clamped(to: 0...60)
    }

    private var queues: [DallasTeam: [DelayedScoreEvent]] = [:]
    private var timer: Timer?

    private init() {
        // Set default delay if not configured (legacy)
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
        currentStation = nil
    }

    private func processQueues() {
        let now = Date()
        let delay = effectiveDelaySeconds

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
