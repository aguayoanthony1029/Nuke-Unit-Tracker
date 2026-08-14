import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \Bet.placedAt, order: .reverse) private var bets: [Bet]
    @State private var month = Date()
    private var summary: DashboardSummary { StatisticsService.summary(for: bets) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    NukeCard { HStack { VStack(alignment: .leading) { Text("ALL-TIME RECORD").font(.caption.bold()).foregroundStyle(NukeTheme.muted); Text(summary.record.label).font(.system(size: 31, weight: .heavy, design: .rounded)) }; Spacer(); VStack(alignment: .trailing) { Text("P&L").font(.caption.bold()).foregroundStyle(NukeTheme.muted); Text(summary.netUnits.unitText).font(.title.bold()).foregroundStyle(summary.netUnits >= 0 ? NukeTheme.green : NukeTheme.red) } } }
                    CalendarUnitsView(month: month, bets: bets)
                    breakdown
                }.padding()
            }
            .background(NukeTheme.background).navigationTitle("Stats")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { DatePicker("Month", selection: $month, displayedComponents: .date).labelsHidden() } }
        }
    }

    private var breakdown: some View {
        NukeCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("UNITS BY SPORT").font(.caption.bold()).foregroundStyle(NukeTheme.muted)
                Chart(sportTotals, id: \.sport) { item in BarMark(x: .value("Units", item.total), y: .value("Sport", item.sport)).foregroundStyle(item.total >= 0 ? NukeTheme.green : NukeTheme.red) }.frame(height: max(110, CGFloat(sportTotals.count) * 40))
            }
        }
    }
    private var sportTotals: [(sport: String, total: Double)] { Dictionary(grouping: bets.filter { $0.result != .pending }, by: \.sport).map { ($0.key, $0.value.reduce(0) { $0 + $1.profitUnits }) }.sorted { abs($0.total) > abs($1.total) } }
}

private struct CalendarUnitsView: View {
    let month: Date
    let bets: [Bet]
    private let calendar = Calendar.current
    var body: some View {
        NukeCard {
            VStack(spacing: 10) {
                HStack { Text(month.formatted(.dateTime.month(.wide).year())).font(.headline); Spacer() }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
                    ForEach(calendar.shortWeekdaySymbols, id: \.self) { Text($0.prefix(1)).font(.caption2.bold()).foregroundStyle(NukeTheme.muted).frame(maxWidth: .infinity) }
                    ForEach(days, id: \.self) { day in
                        if let day { DayCell(day: day, total: total(for: day)) } else { Color.clear.frame(height: 46) }
                    }
                }
            }
        }
    }
    private var days: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month), let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else { return [] }
        let leading = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: leading) + range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: start) }
    }
    private func total(for day: Date) -> Double { bets.filter { calendar.isDate($0.placedAt, inSameDayAs: day) }.reduce(0) { $0 + $1.profitUnits } }
}

private struct DayCell: View {
    let day: Date; let total: Double
    var body: some View {
        VStack(spacing: 2) { Text(day.formatted(.dateTime.day())).font(.caption.bold()); if total != 0 { Text(total.unitText).font(.system(size: 9, weight: .bold)).lineLimit(1) } }
            .foregroundStyle(total > 0 ? NukeTheme.green : total < 0 ? NukeTheme.red : .white.opacity(0.7))
            .frame(maxWidth: .infinity, minHeight: 46)
            .background((total > 0 ? NukeTheme.green : total < 0 ? NukeTheme.red : NukeTheme.surface).opacity(total == 0 ? 0.32 : 0.15), in: RoundedRectangle(cornerRadius: 7))
    }
}

