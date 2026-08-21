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
                        accent: NukeTheme.cyan
                    )
                    NukePerformanceCard(
                        eyebrow: "Sportsbook audit",
                        title: "Units by book",
                        items: bookTotals,
                        accent: NukeTheme.ember
                    )
                    NukePerformanceCard(
                        eyebrow: "Ticket profile",
                        title: "Units by bet type",
                        items: typeTotals,
                        accent: NukeTheme.orange
                    )
                }
                .padding()
                .padding(.bottom, 18)
            }
            .background(NukeCommandBackdrop())
            .navigationTitle("Stats")
        }
    }

    private var commandSummary: some View {
        NukeCard {
            VStack(alignment: .leading, spacing: 13) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ALL-TIME COMMAND LOG")
                            .font(.caption2.weight(.heavy))
                            .tracking(1.1)
                            .foregroundStyle(NukeTheme.muted)
                        Text(summary.record.label)
                            .font(.system(size: 33, weight: .heavy, design: .rounded))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("NET UNITS")
                            .font(.caption2.weight(.heavy))
                            .tracking(1.1)
                            .foregroundStyle(NukeTheme.muted)
                        Text(summary.netUnits.unitText)
                            .font(.title.bold())
                            .foregroundStyle(summary.netUnits >= 0 ? NukeTheme.green : NukeTheme.red)
                    }
                }
                Divider().overlay(NukeTheme.border)
                HStack(spacing: 8) {
                    statCell("ROI", summary.roi, format: .percent.precision(.fractionLength(1)), color: NukeTheme.cyan)
                    statCell("AVG STAKE", summary.averageStake.plainUnitText, color: NukeTheme.orange)
                    statCell("AVG ODDS", averageDecimalOdds == 0 ? "--" : String(format: "%.2f", averageDecimalOdds), color: NukeTheme.ember)
                }
            }
        }
    }

    private func statCell<F: FormatStyle>(_ label: String, _ value: F.FormatInput, format: F, color: Color) -> some View where F.FormatOutput == String {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption2.weight(.bold)).foregroundStyle(NukeTheme.muted)
            Text(format.format(value)).font(.subheadline.weight(.black)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statCell(_ label: String, _ value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption2.weight(.bold)).foregroundStyle(NukeTheme.muted)
            Text(value).font(.subheadline.weight(.black)).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func totals(by key: (Bet) -> String) -> [PerformanceItem] {
        Dictionary(grouping: settledBets, by: key)
            .map { PerformanceItem(label: $0.key, netUnits: $0.value.reduce(0) { $0 + $1.profitUnits }) }
            .sorted { abs($0.netUnits) > abs($1.netUnits) }
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
        NukeCard {
            VStack(alignment: .leading, spacing: 12) {
                NukeSectionHeader(eyebrow: eyebrow, title: title)
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
                        .foregroundStyle(item.netUnits >= 0 ? NukeTheme.green : NukeTheme.red)
                        .annotation(position: item.netUnits >= 0 ? .trailing : .leading) {
                            Text(item.netUnits.unitText)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(item.netUnits >= 0 ? NukeTheme.green : NukeTheme.red)
                        }
                    }
                    .chartXAxis { AxisMarks(position: .bottom) }
                    .chartYAxis { AxisMarks(position: .leading) }
                    .frame(height: max(118, CGFloat(items.count) * 42))
                }
            }
        }
    }
}

private struct CalendarUnitsView: View {
    @Binding var month: Date
    let bets: [Bet]
    private let calendar = Calendar.current

    var body: some View {
        NukeCard {
            VStack(spacing: 11) {
                HStack {
                    Button { shiftMonth(-1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.weight(.bold))
                            .frame(width: 34, height: 34)
                            .background(NukeTheme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Previous month")

                    Spacer()
                    VStack(spacing: 2) {
                        Text("DAILY UNIT CALENDAR")
                            .font(.caption2.weight(.heavy))
                            .tracking(1.1)
                            .foregroundStyle(NukeTheme.muted)
                        Text(month.formatted(.dateTime.month(.wide).year()))
                            .font(.headline.weight(.black))
                    }
                    Spacer()

                    Button { shiftMonth(1) } label: {
                        Image(systemName: "chevron.right")
                            .font(.subheadline.weight(.bold))
                            .frame(width: 34, height: 34)
                            .background(NukeTheme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Next month")
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 5) {
                    ForEach(calendar.shortWeekdaySymbols, id: \.self) {
                        Text(String($0.prefix(1)))
                            .font(.caption2.bold())
                            .foregroundStyle(NukeTheme.muted)
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
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(NukeTheme.muted)
                    Spacer()
                    Text(monthTotal.unitText)
                        .font(.headline.weight(.black))
                        .foregroundStyle(monthTotal >= 0 ? NukeTheme.green : NukeTheme.red)
                }
                .padding(.top, 4)
            }
        }
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
            Text(day.formatted(.dateTime.day())).font(.caption.bold())
            if total != 0 {
                Text(total.unitText)
                    .font(.system(size: 9, weight: .bold))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(total > 0 ? NukeTheme.green : total < 0 ? NukeTheme.red : .white.opacity(0.7))
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(
            (total > 0 ? NukeTheme.green : total < 0 ? NukeTheme.red : NukeTheme.surface)
                .opacity(total == 0 ? 0.32 : 0.15),
            in: RoundedRectangle(cornerRadius: 7)
        )
        .accessibilityLabel("\(day.formatted(date: .abbreviated, time: .omitted)), \(total.unitText)")
    }
}
