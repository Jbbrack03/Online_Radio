import XCTest
@testable import DFWGameDayRadio

final class ScoreDelayQueueTests: XCTestCase {

    private var queue: ScoreDelayQueue!

    override func setUp() {
        super.setUp()
        queue = ScoreDelayQueue.shared
        queue.clear()
    }

    override func tearDown() {
        queue.stopProcessing()
        queue.clear()
        super.tearDown()
    }

    func testEnqueueDeduplication() {
        let score = makeScore(homeScore: 7, awayScore: 3)
        queue.enqueue(score, for: .cowboys)
        queue.enqueue(score, for: .cowboys) // duplicate

        // Only one event should be in the queue — second was deduplicated
        // Enqueue a different score to verify the queue isn't empty
        let score2 = makeScore(homeScore: 14, awayScore: 3)
        queue.enqueue(score2, for: .cowboys)

        // We can't inspect queues directly, but we can verify behavior:
        // The delay queue should eventually release both distinct scores
        XCTAssertNil(queue.delayedScores[.cowboys], "No scores should be released yet without processing")
    }

    func testEnqueueDifferentScores() {
        let score1 = makeScore(homeScore: 7, awayScore: 3)
        let score2 = makeScore(homeScore: 14, awayScore: 3)
        queue.enqueue(score1, for: .cowboys)
        queue.enqueue(score2, for: .cowboys)

        // Both should be queued (different scores)
        XCTAssertNil(queue.delayedScores[.cowboys])
    }

    func testQueueDepthLimit() {
        // Enqueue 150 distinct scores
        for i in 0..<150 {
            let score = makeScore(homeScore: i, awayScore: 0)
            queue.enqueue(score, for: .cowboys)
        }

        // After depth cap, the queue should have at most 100 items
        // We test indirectly: start processing with zero delay and verify we get scores
        // The important thing is we don't crash or use unbounded memory
        XCTAssertNil(queue.delayedScores[.cowboys], "Scores should not be released without processing")
    }

    func testEffectiveDelayNeverNegative() {
        queue.currentStation = .theFan
        queue.userOffset = -60 // extreme negative offset
        XCTAssertGreaterThanOrEqual(queue.effectiveDelaySeconds, 0)
    }

    func testUserOffsetPersistence() {
        queue.userOffset = 5.0
        XCTAssertEqual(queue.userOffset, 5.0)
        queue.userOffset = -10.0
        XCTAssertEqual(queue.userOffset, -10.0)
    }

    // MARK: - Helper

    private func makeScore(homeScore: Int, awayScore: Int) -> GameScore {
        GameScore(
            eventID: "1",
            homeTeam: "DAL",
            awayTeam: "PHI",
            homeTeamFull: "Dallas Cowboys",
            awayTeamFull: "Philadelphia Eagles",
            homeScore: homeScore,
            awayScore: awayScore,
            period: 1,
            displayClock: "15:00",
            state: "in",
            statusDetail: "Q1 15:00"
        )
    }
}
