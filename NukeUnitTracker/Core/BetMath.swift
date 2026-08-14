import Foundation

enum OddsConverter {
    static func decimal(from input: Double, format: OddsFormat) -> Double {
        switch format {
        case .decimal: max(input, 1.01)
        case .american: input >= 100 ? 1 + input / 100 : 1 + 100 / max(abs(input), 1)
        }
    }

    static func american(from decimal: Double) -> Double {
        let d = max(decimal, 1.01)
        return d >= 2 ? (d - 1) * 100 : -100 / (d - 1)
    }
}

enum BetMath {
    static func profitUnits(for bet: Bet) -> Double {
        switch bet.result {
        case .win: bet.riskUnits * (bet.oddsDecimal - 1)
        case .loss: -bet.riskUnits
        case .pending, .push, .void: 0
        }
    }

    static func impliedProbability(decimalOdds: Double) -> Double { 1 / max(decimalOdds, 1.01) }
}

struct Record: Equatable {
    var wins = 0; var losses = 0; var pushes = 0
    var label: String { "\(wins)-\(losses)-\(pushes)" }
}

enum Period: String, CaseIterable, Identifiable { case day, week, month, year; var id: String { rawValue }; var title: String { rawValue.capitalized } }

struct DashboardSummary {
    let netUnits: Double
    let record: Record
    let winRate: Double
    let roi: Double
    let pendingExposure: Double
    let averageStake: Double
    let streak: String
}

enum StatisticsService {
    static func filtered(_ bets: [Bet], period: Period, reference: Date = .now, calendar: Calendar = .current) -> [Bet] {
        bets.filter { bet in
            switch period {
            case .day: calendar.isDate(bet.placedAt, inSameDayAs: reference)
            case .week: calendar.isDate(bet.placedAt, equalTo: reference, toGranularity: .weekOfYear)
            case .month: calendar.isDate(bet.placedAt, equalTo: reference, toGranularity: .month)
            case .year: calendar.isDate(bet.placedAt, equalTo: reference, toGranularity: .year)
            }
        }
    }

    static func summary(for bets: [Bet]) -> DashboardSummary {
        let settled = bets.filter { $0.result != .pending }
        let wins = settled.filter { $0.result == .win }.count
        let losses = settled.filter { $0.result == .loss }.count
        let pushes = settled.filter { $0.result == .push || $0.result == .void }.count
        let risk = settled.reduce(0) { $0 + $1.riskUnits }
        let net = settled.reduce(0) { $0 + $1.profitUnits }
        let decisions = wins + losses
        let pending = bets.filter { $0.result == .pending }.reduce(0) { $0 + $1.riskUnits }
        let average = bets.isEmpty ? 0 : bets.reduce(0) { $0 + $1.riskUnits } / Double(bets.count)
        return DashboardSummary(netUnits: net, record: Record(wins: wins, losses: losses, pushes: pushes), winRate: decisions == 0 ? 0 : Double(wins) / Double(decisions), roi: risk == 0 ? 0 : net / risk, pendingExposure: pending, averageStake: average, streak: streak(for: settled))
    }

    static func cumulativePoints(for bets: [Bet]) -> [(Date, Double)] {
        var running = 0.0
        return bets.sorted { $0.placedAt < $1.placedAt }.map { bet in running += bet.profitUnits; return (bet.placedAt, running) }
    }

    private static func streak(for bets: [Bet]) -> String {
        guard let last = bets.sorted(by: { $0.placedAt > $1.placedAt }).first, last.result == .win || last.result == .loss else { return "—" }
        let target = last.result
        let count = bets.sorted { $0.placedAt > $1.placedAt }.prefix { $0.result == target }.count
        return "\(target == .win ? "W" : "L")\(count)"
    }
}

