import AVFoundation
import Foundation

/// Estimates the delay between the live radio broadcast and the internet stream.
/// Uses three strategies in priority order:
/// 1. HLS probe — briefly connect to the station's HLS fallback to read `currentDate()`
/// 2. Cached measurement — per-station latency from a previous session
/// 3. Research-based defaults — known typical delays per streaming platform
@Observable
class StreamLatencyEstimator {
    static let shared = StreamLatencyEstimator()

    /// Most recent measured or estimated latency per station (seconds behind real-time).
    var estimatedLatency: [RadioStation: TimeInterval] = [:]

    /// Rolling average of how long league APIs take to deliver score events.
    var apiLatency: TimeInterval = 0

    /// Whether an HLS probe is currently running.
    var isProbing = false

    /// How the current estimate was determined.
    var estimateSource: [RadioStation: EstimateSource] = [:]

    enum EstimateSource: String {
        case hlsProbe = "Auto-detected"
        case cached = "Previous session"
        case defaultEstimate = "Default estimate"
    }

    // Research-based defaults per station
    private static let defaults: [RadioStation: TimeInterval] = [
        .theFan: 30,   // Audacy/AmperWave progressive AAC
        .theEagle: 15, // iHeartMedia Shoutcast
        .theTicket: 10  // Triton Digital with burst-time=0
    ]

    private var probePlayer: AVPlayer?
    private var probeItem: AVPlayerItem?
    private var probeObservation: NSKeyValueObservation?
    private var probeTimeoutTask: Task<Void, Never>?
    private var apiLatencySamples: [TimeInterval] = []

    private init() {
        loadCachedLatencies()
    }

    // MARK: - Public API

    /// Start probing the station's stream latency. Non-blocking — results update `estimatedLatency` asynchronously.
    func probe(station: RadioStation) {
        // If we already have an HLS probe result for this station, skip
        if estimateSource[station] == .hlsProbe { return }

        guard let hlsURLString = station.hlsFallbackURL,
              let hlsURL = URL(string: hlsURLString) else {
            // No HLS fallback available — use cached or default
            if estimatedLatency[station] == nil {
                estimatedLatency[station] = Self.defaults[station] ?? 20
                estimateSource[station] = .defaultEstimate
            }
            return
        }

        isProbing = true
        probeViaHLS(station: station, url: hlsURL)
    }

    /// Stop any in-progress probe.
    func stopProbing() {
        cleanupProbe()
    }

    /// Record an API delivery latency sample (call when a score event arrives).
    func recordAPILatency(_ latency: TimeInterval) {
        guard latency > 0, latency < 120 else { return }
        apiLatencySamples.append(latency)
        // Keep rolling window of last 20 samples
        if apiLatencySamples.count > 20 {
            apiLatencySamples.removeFirst()
        }
        apiLatency = apiLatencySamples.reduce(0, +) / Double(apiLatencySamples.count)
    }

    /// Compute the effective score delay for the given station.
    /// Returns how long to hold scores in the queue before releasing them.
    func effectiveDelay(for station: RadioStation, userOffset: TimeInterval) -> TimeInterval {
        let streamDelay = estimatedLatency[station] ?? Self.defaults[station] ?? 20
        let delay = streamDelay - apiLatency + userOffset
        return max(0, delay)
    }

    /// Measure the local buffer depth on the current stream (lower-bound on stream delay).
    func measureBufferDepth() -> TimeInterval? {
        guard let item = AudioStreamManager.shared.currentPlayerItem else { return nil }
        let currentSeconds = CMTimeGetSeconds(item.currentTime())
        guard let loaded = item.loadedTimeRanges.first?.timeRangeValue else { return nil }
        let loadedEnd = CMTimeGetSeconds(loaded.start + loaded.duration)
        return loadedEnd - currentSeconds
    }

    // MARK: - HLS Probe

    private func probeViaHLS(station: RadioStation, url: URL) {
        cleanupProbe()

        probeItem = AVPlayerItem(url: url)
        probePlayer = AVPlayer(playerItem: probeItem)
        probePlayer?.isMuted = true

        // Observe readyToPlay, then check currentDate()
        probeObservation = probeItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                switch item.status {
                case .readyToPlay:
                    self.probePlayer?.play()
                    // Give it a moment to start streaming, then read currentDate
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        await MainActor.run {
                            self.readProbeResult(station: station)
                        }
                    }
                case .failed:
                    self.handleProbeFailed(station: station)
                default:
                    break
                }
            }
        }

        // Timeout after 8 seconds
        probeTimeoutTask = Task {
            try? await Task.sleep(for: .seconds(8))
            await MainActor.run { [weak self] in
                guard let self, self.isProbing else { return }
                self.handleProbeFailed(station: station)
            }
        }
    }

    private func readProbeResult(station: RadioStation) {
        if let streamDate = probeItem?.currentDate() {
            let latency = Date().timeIntervalSince(streamDate)
            if latency > 0 && latency < 300 {
                estimatedLatency[station] = latency
                estimateSource[station] = .hlsProbe
                cacheLatency(latency, for: station)
            }
        } else {
            // HLS stream didn't have EXT-X-PROGRAM-DATE-TIME — use cached/default
            handleProbeFailed(station: station)
            return
        }
        cleanupProbe()
    }

    private func handleProbeFailed(station: RadioStation) {
        if estimatedLatency[station] == nil {
            estimatedLatency[station] = Self.defaults[station] ?? 20
            estimateSource[station] = estimateSource[station] ?? .defaultEstimate
        }
        cleanupProbe()
    }

    private func cleanupProbe() {
        probePlayer?.pause()
        probePlayer = nil
        probeItem = nil
        probeObservation?.invalidate()
        probeObservation = nil
        probeTimeoutTask?.cancel()
        probeTimeoutTask = nil
        isProbing = false
    }

    // MARK: - Caching

    private func loadCachedLatencies() {
        for station in RadioStation.allCases {
            let key = UserDefaultsKeys.cachedLatency(for: station.rawValue)
            let cached = UserDefaults.standard.double(forKey: key)
            if cached > 0 {
                estimatedLatency[station] = cached
                estimateSource[station] = .cached
            } else {
                estimatedLatency[station] = Self.defaults[station]
                estimateSource[station] = .defaultEstimate
            }
        }
    }

    private func cacheLatency(_ latency: TimeInterval, for station: RadioStation) {
        let key = UserDefaultsKeys.cachedLatency(for: station.rawValue)
        UserDefaults.standard.set(latency, forKey: key)
    }
}
