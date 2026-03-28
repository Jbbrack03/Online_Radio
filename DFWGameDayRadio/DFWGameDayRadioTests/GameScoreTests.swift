import XCTest
@testable import DFWGameDayRadio

final class GameScoreTests: XCTestCase {

    func testClockDisplayPre() {
        let score = makeScore(state: "pre", statusDetail: "7:30 PM CT")
        XCTAssertEqual(score.clockDisplay, "Pregame")
    }

    func testClockDisplayPost() {
        let score = makeScore(state: "post", statusDetail: "Final")
        XCTAssertEqual(score.clockDisplay, "Final")
    }

    func testClockDisplayLive() {
        let score = makeScore(state: "in", statusDetail: "Q3 8:42")
        XCTAssertEqual(score.clockDisplay, "Q3 8:42")
    }

    func testIsLive() {
        XCTAssertTrue(makeScore(state: "in").isLive)
        XCTAssertFalse(makeScore(state: "pre").isLive)
        XCTAssertFalse(makeScore(state: "post").isLive)
    }

    func testScoreLine() {
        let score = makeScore(homeTeam: "DAL", awayTeam: "PHI", homeScore: 21, awayScore: 14)
        XCTAssertEqual(score.scoreLine, "DAL 21 - 14 PHI")
    }

    func testCodableRoundTrip() throws {
        let score = makeScore(state: "in", statusDetail: "Q2 5:00")
        let data = try JSONEncoder().encode(score)
        let decoded = try JSONDecoder().decode(GameScore.self, from: data)
        XCTAssertEqual(score, decoded)
    }

    func testCodableRoundTripWithSituation() throws {
        var score = makeScore(state: "in")
        score.situation = .baseball(BaseballSituation(
            inning: 5, inningHalf: "top",
            balls: 2, strikes: 1, outs: 1,
            runnerOnFirst: true, runnerOnSecond: false, runnerOnThird: false,
            batterName: "Corey Seager", pitcherName: "Max Scherzer"
        ))
        let data = try JSONEncoder().encode(score)
        let decoded = try JSONDecoder().decode(GameScore.self, from: data)
        XCTAssertEqual(score, decoded)
    }

    // MARK: - Helper

    private func makeScore(
        homeTeam: String = "DAL",
        awayTeam: String = "PHI",
        homeScore: Int = 10,
        awayScore: Int = 7,
        state: String = "in",
        statusDetail: String = "Q3 8:42"
    ) -> GameScore {
        GameScore(
            eventID: "1",
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            homeTeamFull: "Dallas",
            awayTeamFull: "Philadelphia",
            homeScore: homeScore,
            awayScore: awayScore,
            period: 3,
            displayClock: "8:42",
            state: state,
            statusDetail: statusDetail
        )
    }
}
