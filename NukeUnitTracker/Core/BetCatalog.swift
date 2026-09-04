import Foundation

enum BetCatalog {
    static let sports = [
        "NBA",
        "NFL",
        "College Football",
        "MLB",
        "College Baseball",
        "NHL",
        "NCAAB",
        "Soccer",
        "Tennis",
        "Table Tennis",
        "Golf",
        "Other"
    ]

    static let sportsbooks = [
        "1xBet",
        "Bally Bet",
        "bet365",
        "BetMGM",
        "BetOnline",
        "betParx",
        "Betr",
        "BetRivers",
        "Borgata Sportsbook",
        "Bovada",
        "Caesars Sportsbook",
        "Circa Sports",
        "Desert Diamond Sports",
        "DraftKings",
        "ESPN Bet",
        "Fanatics Sportsbook",
        "FanDuel",
        "Fliff",
        "Hard Rock Bet",
        "Pinnacle",
        "PrizePicks",
        "Stake",
        "SuperBook Sports",
        "theScore Bet",
        "TwinSpires",
        "Underdog Fantasy"
    ]

    static func symbol(for sport: String) -> String {
        [
            "NBA": "basketball.fill",
            "NFL": "football.fill",
            "College Football": "football.fill",
            "MLB": "baseball.fill",
            "College Baseball": "baseball.fill",
            "NHL": "hockey.puck.fill",
            "NCAAB": "basketball.fill",
            "Soccer": "soccerball",
            "Tennis": "figure.tennis",
            "Table Tennis": "figure.table.tennis",
            "Golf": "figure.golf"
        ][sport] ?? "sportscourt.fill"
    }
}
