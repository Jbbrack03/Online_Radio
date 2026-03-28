import XCTest
@testable import DFWGameDayRadio

final class ModelTests: XCTestCase {

    // MARK: - RadioStation

    func testRadioStationProperties() {
        XCTAssertEqual(RadioStation.theFan.displayName, "105.3 The Fan")
        XCTAssertEqual(RadioStation.theEagle.callSign, "KEGL-FM")
        XCTAssertEqual(RadioStation.theTicket.teams, [.stars])
        XCTAssertEqual(RadioStation.theFan.teams, [.cowboys, .rangers])
        XCTAssertEqual(RadioStation.theEagle.teams, [.mavericks])
    }

    func testRadioStationStreamURLs() {
        for station in RadioStation.allCases {
            XCTAssertFalse(station.streamURL.isEmpty, "\(station) has empty stream URL")
            XCTAssertNotNil(URL(string: station.streamURL), "\(station) has invalid stream URL")
        }
    }

    // MARK: - DallasTeam

    func testDallasTeamProperties() {
        XCTAssertEqual(DallasTeam.cowboys.sport, "NFL")
        XCTAssertEqual(DallasTeam.rangers.sport, "MLB")
        XCTAssertEqual(DallasTeam.mavericks.sport, "NBA")
        XCTAssertEqual(DallasTeam.stars.sport, "NHL")
    }

    func testDallasTeamStationMapping() {
        XCTAssertEqual(DallasTeam.cowboys.station, .theFan)
        XCTAssertEqual(DallasTeam.rangers.station, .theFan)
        XCTAssertEqual(DallasTeam.mavericks.station, .theEagle)
        XCTAssertEqual(DallasTeam.stars.station, .theTicket)
    }

    func testDallasTeamESPNIDs() {
        XCTAssertEqual(DallasTeam.cowboys.espnTeamID, "6")
        XCTAssertEqual(DallasTeam.rangers.espnTeamID, "13")
        XCTAssertEqual(DallasTeam.mavericks.espnTeamID, "7")
        XCTAssertEqual(DallasTeam.stars.espnTeamID, "25")
    }

    func testDallasTeamColors() {
        for team in DallasTeam.allCases {
            XCTAssertTrue(team.primaryColor.hasPrefix("#"), "\(team) primary color missing # prefix")
            XCTAssertTrue(team.secondaryColor.hasPrefix("#"), "\(team) secondary color missing # prefix")
        }
    }

    // MARK: - GameSituation microSummary

    func testBaseballMicroSummary() {
        let situation = GameSituation.baseball(BaseballSituation(
            inning: 3, inningHalf: "top",
            balls: 1, strikes: 2, outs: 2,
            runnerOnFirst: true, runnerOnSecond: false, runnerOnThird: true,
            batterName: "Corey Seager", pitcherName: "Max Scherzer"
        ))
        let summary = situation.microSummary
        XCTAssertTrue(summary.contains("Top 3rd"))
        XCTAssertTrue(summary.contains("1-2"))
        XCTAssertTrue(summary.contains("2 Outs"))
        XCTAssertTrue(summary.contains("1st/3rd"))
    }

    func testFootballMicroSummary() {
        let situation = GameSituation.football(FootballSituation(
            down: 3, distance: 7, yardLine: 45,
            possession: "DAL", lastPlay: nil
        ))
        XCTAssertEqual(situation.microSummary, "3rd & 7 at DAL 45")
    }

    func testBasketballMicroSummary() {
        let situation = GameSituation.basketball(BasketballSituation(
            timeoutsHome: 4, timeoutsAway: 3,
            bonusHome: true, bonusAway: false
        ))
        let summary = situation.microSummary
        XCTAssertTrue(summary.contains("Bonus"))
        XCTAssertTrue(summary.contains("TO: 3-4"))
    }

    func testHockeyMicroSummary() {
        let situation = GameSituation.hockey(HockeySituation(
            powerPlay: true, powerPlayTeam: "DAL",
            powerPlayTimeRemaining: "1:32",
            shotsHome: 25, shotsAway: 18
        ))
        let summary = situation.microSummary
        XCTAssertTrue(summary.contains("PP DAL 1:32"))
        XCTAssertTrue(summary.contains("SOG 18-25"))
    }

    func testHockeyMicroSummaryNoPowerPlay() {
        let situation = GameSituation.hockey(HockeySituation(
            powerPlay: false, powerPlayTeam: nil,
            powerPlayTimeRemaining: nil,
            shotsHome: 30, shotsAway: 22
        ))
        XCTAssertEqual(situation.microSummary, "SOG 22-30")
    }

    // MARK: - Int.ordinal

    func testOrdinals() {
        XCTAssertEqual(1.ordinal, "1st")
        XCTAssertEqual(2.ordinal, "2nd")
        XCTAssertEqual(3.ordinal, "3rd")
        XCTAssertEqual(4.ordinal, "4th")
        XCTAssertEqual(11.ordinal, "11th")
        XCTAssertEqual(12.ordinal, "12th")
        XCTAssertEqual(13.ordinal, "13th")
        XCTAssertEqual(21.ordinal, "21st")
        XCTAssertEqual(22.ordinal, "22nd")
        XCTAssertEqual(23.ordinal, "23rd")
    }
}
