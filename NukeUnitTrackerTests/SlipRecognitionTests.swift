import XCTest
@testable import NukeUnitTracker

final class SlipRecognitionTests: XCTestCase {
    func testScannerParsesCommonSlipDetails() {
        let result = SlipRecognizer.parse(text: """
        FanDuel
        NFL Same Game Parlay
        Kansas City Chiefs @ Buffalo Bills
        Total Odds +275
        Stake $20.00
        """)

        XCTAssertEqual(result.sportsbook, "FanDuel")
        XCTAssertEqual(result.sport, "NFL")
        XCTAssertEqual(result.kind, .sameGameParlay)
        XCTAssertEqual(result.title, "Kansas City Chiefs @ Buffalo Bills")
        XCTAssertEqual(result.odds, 275)
        XCTAssertEqual(result.oddsFormat, .american)
        XCTAssertEqual(result.riskDollars, 20)
    }

    func testScannerRecognizesAddedSportsAndDecimalOdds() {
        let result = SlipRecognizer.parse(text: """
        bet365
        Table Tennis
        Total Odds: 1.91
        Wager: $12.50
        """)

        XCTAssertEqual(result.sportsbook, "bet365")
        XCTAssertEqual(result.sport, "Table Tennis")
        XCTAssertEqual(result.odds, 1.91)
        XCTAssertEqual(result.oddsFormat, .decimal)
        XCTAssertEqual(result.riskDollars, 12.5)
    }

    func testScannerBuildsPlayerPropSelectionFromSeparateLines() {
        let result = SlipRecognizer.parse(text: """
        DraftKings
        NFL
        CeeDee Lamb
        Over 67.5
        Receiving Yards
        -110
        Stake $10.00
        """)

        XCTAssertEqual(result.title, "CeeDee Lamb — Over 67.5 — Receiving Yards")
        XCTAssertEqual(result.odds, -110)
        XCTAssertEqual(result.riskDollars, 10)
    }

    func testScannerBuildsTeamSpreadSelection() {
        let result = SlipRecognizer.parse(text: """
        FanDuel
        NBA
        Los Angeles Lakers -3.5
        Point Spread
        Total Odds -115
        Wager $15
        """)

        XCTAssertEqual(result.title, "Los Angeles Lakers -3.5 — Point Spread")
        XCTAssertEqual(result.odds, -115)
        XCTAssertEqual(result.riskDollars, 15)
    }

    func testScannerPrefersCompleteOneLineSelectionOverMatchup() {
        let result = SlipRecognizer.parse(text: """
        NBA
        Boston Celtics @ New York Knicks
        Jayson Tatum Over 24.5 Points
        Total Odds -110
        """)

        XCTAssertEqual(result.title, "Jayson Tatum Over 24.5 Points")
    }

    func testScannerRecognizesPlayerAndSpecialtyMarketsAcrossSports() {
        let cases: [(text: String, expectedTitle: String)] = [
            ("""
            BetMGM
            MLB
            Aaron Judge
            Over 1.5
            Total Bases
            """, "Aaron Judge — Over 1.5 — Total Bases"),
            ("""
            Caesars
            NHL
            Auston Matthews
            3+
            Shots on Goal
            """, "Auston Matthews — 3+ — Shots on Goal"),
            ("""
            FanDuel
            Soccer
            Lionel Messi
            Anytime Goalscorer
            """, "Lionel Messi — Anytime Goalscorer"),
            ("""
            bet365
            Tennis
            Coco Gauff
            Over 20.5
            Total Games
            """, "Coco Gauff — Over 20.5 — Total Games"),
            ("""
            DraftKings
            Golf
            Scottie Scheffler
            Top 10 Finish
            """, "Scottie Scheffler — Top 10 Finish"),
            ("""
            FanDuel
            Table Tennis
            Ma Long
            Match Winner
            """, "Ma Long — Match Winner"),
            ("""
            BetMGM
            UFC
            Alex Pereira
            Over 1.5 Rounds
            """, "Alex Pereira — Over 1.5 Rounds")
        ]

        for testCase in cases {
            XCTAssertEqual(SlipRecognizer.parse(text: testCase.text).title, testCase.expectedTitle)
        }
    }

    func testParlaySelectionsMergeAcrossScreenshotsWithoutDuplicates() {
        let firstScreenshot = [
            "CeeDee Lamb — Over 67.5 — Receiving Yards",
            "Jayson Tatum Over 24.5 Points"
        ]
        let nextScreenshot = [
            "Jayson Tatum — Over 24.5 — Points",
            "Aaron Judge — Over 1.5 — Total Bases"
        ]

        let result = SlipRecognizer.mergeSelections(existing: firstScreenshot, adding: nextScreenshot)

        XCTAssertEqual(result.selections, [
            "CeeDee Lamb — Over 67.5 — Receiving Yards",
            "Jayson Tatum Over 24.5 Points",
            "Aaron Judge — Over 1.5 — Total Bases"
        ])
        XCTAssertEqual(result.addedCount, 1)
        XCTAssertEqual(result.duplicatesSkipped, 1)
    }
}
