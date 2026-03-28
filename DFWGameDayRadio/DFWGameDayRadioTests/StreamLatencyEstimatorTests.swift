import XCTest
@testable import DFWGameDayRadio

final class StreamLatencyEstimatorTests: XCTestCase {

    private var estimator: StreamLatencyEstimator!

    override func setUp() {
        super.setUp()
        estimator = StreamLatencyEstimator.shared
    }

    func testDefaultLatencyValues() {
        // Every station should have an estimated latency (either cached or default)
        for station in RadioStation.allCases {
            let latency = estimator.estimatedLatency[station]
            XCTAssertNotNil(latency, "\(station) should have an estimated latency")
            XCTAssertGreaterThan(latency ?? 0, 0, "\(station) latency should be positive")
        }
    }

    func testEffectiveDelayNeverNegative() {
        // Even with high API latency and negative user offset, delay should be >= 0
        for _ in 0..<30 {
            estimator.recordAPILatency(50) // artificially high API latency
        }
        let delay = estimator.effectiveDelay(for: .theTicket, userOffset: -15)
        XCTAssertGreaterThanOrEqual(delay, 0)
    }

    func testRecordAPILatencySampleAveraging() {
        // Record 5 samples
        let samples: [TimeInterval] = [1.0, 2.0, 3.0, 4.0, 5.0]
        for s in samples {
            estimator.recordAPILatency(s)
        }
        // Average should include these samples (may include prior samples from shared instance)
        XCTAssertGreaterThan(estimator.apiLatency, 0)
    }

    func testRecordAPILatencyRejectsOutOfBounds() {
        let beforeLatency = estimator.apiLatency
        estimator.recordAPILatency(-5)   // negative — should be ignored
        estimator.recordAPILatency(200)  // > 120s — should be ignored
        estimator.recordAPILatency(0)    // zero — should be ignored
        XCTAssertEqual(estimator.apiLatency, beforeLatency, "Out-of-bounds samples should not change apiLatency")
    }

    func testEffectiveDelayPositiveOffsetIncreasesDelay() {
        // Regardless of shared state, a higher offset should give >= equal delay
        let delayAt0 = estimator.effectiveDelay(for: .theFan, userOffset: 0)
        let delayAt10 = estimator.effectiveDelay(for: .theFan, userOffset: 10)
        let delayAt50 = estimator.effectiveDelay(for: .theFan, userOffset: 50)

        XCTAssertGreaterThanOrEqual(delayAt10, delayAt0)
        XCTAssertGreaterThanOrEqual(delayAt50, delayAt10)
        // With a very large offset, delay must be positive
        XCTAssertGreaterThan(delayAt50, 0)
    }
}
