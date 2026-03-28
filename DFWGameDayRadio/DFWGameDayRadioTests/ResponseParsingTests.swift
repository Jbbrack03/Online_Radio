import XCTest
@testable import DFWGameDayRadio

final class ResponseParsingTests: XCTestCase {

    // MARK: - ESPN

    func testDecodeESPNScoreboard() throws {
        let json = """
        {
            "events": [{
                "id": "401547417",
                "name": "Philadelphia Eagles at Dallas Cowboys",
                "shortName": "PHI @ DAL",
                "status": {
                    "clock": 502.0,
                    "displayClock": "8:22",
                    "period": 3,
                    "type": {
                        "id": "2",
                        "name": "STATUS_IN_PROGRESS",
                        "state": "in",
                        "completed": false,
                        "description": "In Progress",
                        "detail": "8:22 - 3rd Quarter",
                        "shortDetail": "Q3 8:22"
                    }
                },
                "competitions": [{
                    "competitors": [
                        {
                            "id": "6",
                            "homeAway": "home",
                            "score": "21",
                            "team": {
                                "id": "6",
                                "abbreviation": "DAL",
                                "displayName": "Dallas Cowboys",
                                "shortDisplayName": "Cowboys",
                                "logo": "https://example.com/dal.png",
                                "color": "003594"
                            }
                        },
                        {
                            "id": "21",
                            "homeAway": "away",
                            "score": "14",
                            "team": {
                                "id": "21",
                                "abbreviation": "PHI",
                                "displayName": "Philadelphia Eagles",
                                "shortDisplayName": "Eagles",
                                "logo": "https://example.com/phi.png",
                                "color": "004C54"
                            }
                        }
                    ],
                    "situation": null
                }]
            }]
        }
        """.data(using: .utf8)!

        let scoreboard = try JSONDecoder().decode(ESPNScoreboard.self, from: json)
        XCTAssertEqual(scoreboard.events.count, 1)

        let event = scoreboard.events[0]
        XCTAssertEqual(event.id, "401547417")
        XCTAssertEqual(event.status.type.state, "in")
        XCTAssertEqual(event.status.displayClock, "8:22")
        XCTAssertEqual(event.status.period, 3)

        let home = event.homeCompetitor
        XCTAssertEqual(home?.team.abbreviation, "DAL")
        XCTAssertEqual(home?.scoreInt, 21)
        XCTAssertEqual(home?.team.id, "6")

        let away = event.awayCompetitor
        XCTAssertEqual(away?.team.abbreviation, "PHI")
        XCTAssertEqual(away?.scoreInt, 14)
    }

    func testDecodeESPNWithMissingOptionals() throws {
        let json = """
        {
            "events": [{
                "id": "1",
                "name": "Test Game",
                "shortName": "TST @ TST",
                "status": {
                    "type": {
                        "state": "pre"
                    }
                },
                "competitions": [{
                    "competitors": [{
                        "id": "1",
                        "homeAway": "home",
                        "team": {
                            "id": "1",
                            "abbreviation": "TST",
                            "displayName": "Test",
                            "shortDisplayName": "Test"
                        }
                    }]
                }]
            }]
        }
        """.data(using: .utf8)!

        let scoreboard = try JSONDecoder().decode(ESPNScoreboard.self, from: json)
        XCTAssertEqual(scoreboard.events.count, 1)
        XCTAssertNil(scoreboard.events[0].status.displayClock)
        XCTAssertNil(scoreboard.events[0].status.period)
        XCTAssertEqual(scoreboard.events[0].homeCompetitor?.scoreInt, 0) // nil score → 0
    }

    // MARK: - NBA

    func testDecodeNBAScoreboard() throws {
        let json = """
        {
            "scoreboard": {
                "games": [{
                    "gameId": "0022300123",
                    "gameStatus": 2,
                    "gameStatusText": "Q3 8:42",
                    "period": 3,
                    "gameClock": "PT08M42.00S",
                    "homeTeam": {
                        "teamId": 1610612742,
                        "teamTricode": "DAL",
                        "teamName": "Mavericks",
                        "teamCity": "Dallas",
                        "score": 87
                    },
                    "awayTeam": {
                        "teamId": 1610612738,
                        "teamTricode": "BOS",
                        "teamName": "Celtics",
                        "teamCity": "Boston",
                        "score": 82
                    }
                }]
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(NBAScoreboardResponse.self, from: json)
        XCTAssertEqual(response.scoreboard.games.count, 1)

        let game = response.scoreboard.games[0]
        XCTAssertEqual(game.gameId, "0022300123")
        XCTAssertEqual(game.gameStatus, 2)
        XCTAssertEqual(game.period, 3)
        XCTAssertEqual(game.gameClock, "PT08M42.00S")
        XCTAssertEqual(game.homeTeam.teamTricode, "DAL")
        XCTAssertEqual(game.homeTeam.score, 87)
        XCTAssertEqual(game.awayTeam.teamTricode, "BOS")
        XCTAssertEqual(game.awayTeam.score, 82)
    }

    // MARK: - MLB

    func testDecodeMLBSchedule() throws {
        let json = """
        {
            "dates": [{
                "games": [{
                    "gamePk": 718765,
                    "status": {
                        "abstractGameState": "Live",
                        "detailedState": "In Progress"
                    },
                    "teams": {
                        "away": {
                            "score": 3,
                            "team": { "id": 117, "name": "Houston Astros", "abbreviation": "HOU" }
                        },
                        "home": {
                            "score": 5,
                            "team": { "id": 140, "name": "Texas Rangers", "abbreviation": "TEX" }
                        }
                    },
                    "linescore": {
                        "currentInning": 5,
                        "inningHalf": "Bottom"
                    }
                }]
            }]
        }
        """.data(using: .utf8)!

        let schedule = try JSONDecoder().decode(MLBSchedule.self, from: json)
        XCTAssertNotNil(schedule.dates)
        XCTAssertEqual(schedule.dates?.first?.games.first?.gamePk, 718765)
    }

    // MARK: - NHL

    func testDecodeNHLScoresResponse() throws {
        let json = """
        {
            "games": [{
                "id": 2023020456,
                "gameState": "LIVE",
                "homeTeam": {
                    "id": 25,
                    "abbrev": "DAL",
                    "score": 3,
                    "sog": 28
                },
                "awayTeam": {
                    "id": 21,
                    "abbrev": "COL",
                    "score": 2,
                    "sog": 22
                }
            }]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(NHLScoresResponse.self, from: json)
        XCTAssertEqual(response.games.count, 1)

        let game = response.games[0]
        XCTAssertEqual(game.id, 2023020456)
        XCTAssertEqual(game.homeTeam.abbrev, "DAL")
        XCTAssertEqual(game.homeTeam.score, 3)
        XCTAssertEqual(game.awayTeam.abbrev, "COL")
        XCTAssertEqual(game.awayTeam.sog, 22)
    }
}
