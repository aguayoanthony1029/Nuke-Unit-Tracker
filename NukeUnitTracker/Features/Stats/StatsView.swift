import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \Bet.placedAt, order: .reverse) private var bets: [Bet]
    @State private var month = Date()

    private var summary: DashboardSummary { StatisticsService.summary(for: bets) }
    private var settledBets: [Bet] { bets.filter { $0.result != .pending } }
    private var averageDecimalOdds: Double {
        guard !bets.isEmpty else { return 0 }
        return bets.reduce(0) { $0 + $1.oddsDecimal } / Double(bets.count)
    }
    private var sportTotals: [PerformanceItem] { totals { $0.sport } }
    private var bookTotals: [PerformanceItem] { totals { $0.sportsbook.isEmpty ? "No book listed" : $0.sportsbook } }
    private var typeTotals: [PerformanceItem] { totals { $0.kind.label } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    commandSummary
                    CalendarUnitsView(month: $month, bets: bets)
                    NukePerformanceCard(
                        eyebrow: "Performance map",
                        title: "Units by sport",
                        items: sportTotals,
                        accent: NukeTheme.hudCyan
                    )
                    NukePerformanceCard(
                        eyebrow: "Sportsbook audit",
                        title: "Units by book",
                        items: bookTotals,
                        accent: NukeTheme.neonOrange
                    )
                    NukePerformanceCard(
                        eyebrow: "Ticket profile",
                        title: "Units by bet type",
                        items: typeTotals,
                        accent: NukeTheme.neonOrange
                    )
                }
                .padding()
                .padding(.bottom, 18)
            }
            .background(NukeTheme.bgBase.ignoresSafeArea())
            .navigationTitle("Stats")
        }
    }

    private var commandSummary: some View {
        VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ALL-TIME COMMAND LOG")
                            .font(NukeTheme.headerFont(size: 12, relativeTo: .caption2))
                            .tracking(1.1)
                            .foregroundStyle(Color.white.opacity(0.50))
                        Text(summary.record.label)
                            .font(NukeTheme.dataFont(size: 33, relativeTo: .title))
                            .foregroundStyle(NukeTheme.hudCyan)
                            .neonGlow(color: NukeTheme.hudCyan)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("NET UNITS")
                            .font(NukeTheme.headerFont(size: 12, relativeTo: .caption2))
                            .tracking(1.1)
                            .foregroundStyle(Color.white.opacity(0.50))
                        Text(summary.netUnits.unitText)
                            .font(NukeTheme.dataFont(size: 30, relativeTo: .title))
                            .foregroundStyle(performanceColor(for: summary.netUnits))
                            .neonGlow(color: performanceColor(for: summary.netUnits))
                    }
                }
                Divider().overlay(NukeTheme.border)
                HStack(spacing: 8) {
                    statCell("ROI", summary.roi, format: .percent.precision(.fractionLength(1)), color: performanceColor(for: summary.roi))
                    statCell("AVG STAKE", summary.averageStake.plainUnitText, color: NukeTheme.neonOrange)
                    statCell("AVG ODDS", averageDecimalOdds == 0 ? "--" : String(format: "%.2f", averageDecimalOdds), color: NukeTheme.hudCyan)
                }
            }
        .padding(16)
        .tacticalCard()
    }

    private func statCell<F: FormatStyle>(_ label: String, _ value: F.FormatInput, format: F, color: Color) -> some View where F.FormatOutput == String {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(NukeTheme.headerFont(size: 11, relativeTo: .caption2))
                .foregroundStyle(Color.white.opacity(0.50))
            Text(format.format(value))
                .font(NukeTheme.dataFont(size: 18, relativeTo: .subheadline))
                .foregroundStyle(color)
                .neonGlow(color: color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statCell(_ label: String, _ value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(NukeTheme.headerFont(size: 11, relativeTo: .caption2))
                .foregroundStyle(Color.white.opacity(0.50))
            Text(value)
                .font(NukeTheme.dataFont(size: 18, relativeTo: .subheadline))
                .foregroundStyle(color)
                .neonGlow(color: color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func totals(by key: (Bet) -> String) -> [PerformanceItem] {
        Dictionary(grouping: settledBets, by: key)
            .map { PerformanceItem(label: $0.key, netUnits: $0.value.reduce(0) { $0 + $1.profitUnits }) }
            .sorted { abs($0.netUnits) > abs($1.netUnits) }
    }

    private func performanceColor(for value: Double) -> Color {
        if value > 0 { return NukeTheme.matrixGreen }
        if value < 0 { return NukeTheme.alertRed }
        return NukeTheme.hudCyan
    }
}

private struct PerformanceItem: Identifiable {
    let label: String
    let netUnits: Double
    var id: String { label }
}

private struct NukePerformanceCard: View {
    let eyebrow: String
    let title: String
    let items: [PerformanceItem]
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(eyebrow.uppercased())
                        .font(NukeTheme.headerFont(size: 11, relativeTo: .caption2))
                        .tracking(1.1)
                        .foregroundStyle(Color.white.opacity(0.50))
                    Text(title.uppercased())
                        .font(NukeTheme.headerFont(size: 15, relativeTo: .subheadline))
                        .tracking(0.8)
                        .foregroundStyle(Color.white.opacity(0.72))
                }
                if items.isEmpty {
                    ContentUnavailableView(
                        "No settled bets yet",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Settle a tracked bet to build this performance map.")
                    )
                    .frame(height: 128)
                } else {
                    Chart(items) { item in
                        BarMark(
                            x: .value("Units", item.netUnits),
                            y: .value("Category", item.label)
                        )
                        .foregroundStyle(performanceColor(for: item.netUnits))
                        .annotation(position: item.netUnits >= 0 ? .trailing : .leading) {
                            Text(item.netUnits.unitText)
                                .font(NukeTheme.dataFont(size: 12, relativeTo: .caption2))
                                .foregroundStyle(performanceColor(for: item.netUnits))
                                .neonGlow(color: performanceColor(for: item.netUnits))
                        }
                    }
                    .chartXAxis { AxisMarks(position: .bottom) }
                    .chartYAxis { AxisMarks(position: .leading) }
                    .frame(height: max(118, CGFloat(items.count) * 42))
                }
            }
        .padding(16)
        .tacticalCard()
        .overlay(alignment: .top) {
            Capsule()
                .fill(accent)
                .frame(height: 1)
                .padding(.horizontal, 14)
                .neonGlow(color: accent)
        }
    }

    private func performanceColor(for value: Double) -> Color {
        if value > 0 { return NukeTheme.matrixGreen }
        if value < 0 { return NukeTheme.alertRed }
        return NukeTheme.hudCyan
    }
}

private struct CalendarUnitsView: View {
    @Binding var month: Date
    let bets: [Bet]
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 11) {
                HStack {
                    Button { shiftMonth(-1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.weight(.bold))
                            .frame(width: 34, height: 34)
                            .background(NukeTheme.bgBase, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Previous month")

                    Spacer()
                    VStack(spacing: 2) {
                        Text("DAILY UNIT CALENDAR")
                            .font(NukeTheme.headerFont(size: 12, relativeTo: .caption2))
                            .tracking(1.1)
                            .foregroundStyle(Color.white.opacity(0.50))
                        Text(month.formatted(.dateTime.month(.wide).year()))
                            .font(NukeTheme.titleFont(size: 20, relativeTo: .headline))
                    }
                    Spacer()

                    Button { shiftMonth(1) } label: {
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.bold))
                            .frame(width: 34, height: 34)
                            .background(NukeTheme.bgBase, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Next month")
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
                    ForEach(calendar.shortWeekdaySymbols, id: \.self) {
                        Text(String($0.prefix(1)))
                            .font(NukeTheme.headerFont(size: 11, relativeTo: .caption2))
                            .foregroundStyle(Color.white.opacity(0.50))
                            .frame(maxWidth: .infinity)
                    }
                    ForEach(days, id: \.self) { day in
                        if let day {
                            DayCell(day: day, total: total(for: day))
                        } else {
                            Color.clear.frame(height: 50)
                        }
                    }
                }
                HStack {
                    Text("MONTH TOTAL")
                        .font(NukeTheme.headerFont(size: 12, relativeTo: .caption2))
                        .foregroundStyle(Color.white.opacity(0.50))
                    Spacer()
                    Text(monthTotal.unitText)
                        .font(NukeTheme.dataFont(size: 22, relativeTo: .headline))
                        .foregroundStyle(monthTotalColor)
                        .neonGlow(color: monthTotalColor)
                }
                .padding(.top, 4)
            }
        .padding(16)
        .tacticalCard()
    }

    private var days: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else { return [] }
        let leading = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: leading) + range.compactMap {
            calendar.date(byAdding: .day, value: $0 - 1, to: start)
        }
    }

    private var monthTotal: Double {
        bets.filter { calendar.isDate($0.placedAt, equalTo: month, toGranularity: .month) }
            .reduce(0) { $0 + $1.profitUnits }
    }

    private var monthTotalColor: Color {
        if monthTotal > 0 { return NukeTheme.matrixGreen }
        if monthTotal < 0 { return NukeTheme.alertRed }
        return NukeTheme.hudCyan
    }

    private func total(for day: Date) -> Double {
        bets.filter { calendar.isDate($0.placedAt, inSameDayAs: day) }
            .reduce(0) { $0 + $1.profitUnits }
    }

    private func shiftMonth(_ offset: Int) {
        month = calendar.date(byAdding: .month, value: offset, to: month) ?? month
    }
}

private struct DayCell: View {
    let day: Date
    let total: Double

    var body: some View {
        VStack(spacing: 2) {
            Text(day.formatted(.dateTime.day()))
                .font(NukeTheme.dataFont(size: 13, relativeTo: .caption))
            if total != 0 {
                Text(total.unitText)
                    .font(NukeTheme.dataFont(size: 10, relativeTo: .caption2))
                    .neonGlow(color: total > 0 ? NukeTheme.matrixGreen : NukeTheme.alertRed)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(total > 0 ? NukeTheme.matrixGreen : total < 0 ? NukeTheme.alertRed : .white.opacity(0.7))
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(
            (total > 0 ? NukeTheme.matrixGreen : total < 0 ? NukeTheme.alertRed : NukeTheme.bgSurface)
                .opacity(total == 0 ? 0.32 : 0.15),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .tacticalCard()
        .accessibilityLabel("\(day.formatted(date: .abbreviated, time: .omitted)), \(total.unitText)")
    }
}
