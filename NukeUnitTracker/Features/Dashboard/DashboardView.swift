import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    let profile: UserProfile
    @Query(sort: \Bet.placedAt, order: .reverse) private var bets: [Bet]
    @State private var period: Period = .month
    @State private var isShowingFeed = false

    private var filtered: [Bet] { StatisticsService.filtered(bets, period: period) }
    private var summary: DashboardSummary { StatisticsService.summary(for: filtered) }
    private var performanceColor: Color { summary.netUnits >= 0 ? NukeTheme.green : NukeTheme.red }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 15) {
                    commandHeader
                    periodRail
                    unitConsole
                    metricGrid
                    UnitsChart(bets: filtered, netUnits: summary.netUnits)
                    FreePicksPreview { isShowingFeed = true }
                    recentBets
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 22)
            }
            .background(NukeCommandBackdrop())
            .navigationDestination(isPresented: $isShowingFeed) { FreePicksView() }
        }
    }

    private var commandHeader: some View {
        HStack(spacing: 11) {
            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 38, height: 38)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(NukeTheme.orange.opacity(0.6), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text("NUKE")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .tracking(1.5)
                Text("COMMAND CENTER")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.05)
                    .foregroundStyle(NukeTheme.orange)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            Spacer(minLength: 8)

            NukeStatusPill(title: "Live", color: NukeTheme.cyan, symbol: "bolt.fill")
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var periodRail: some View {
        HStack(spacing: 5) {
            ForEach(Period.allCases) { option in
                Button {
                    withAnimation(.snappy(duration: 0.22)) { period = option }
                } label: {
                    Text(option.title.uppercased())
                        .font(.caption.weight(.black))
                        .tracking(0.75)
                        .foregroundStyle(period == option ? .black : NukeTheme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(period == option ? NukeTheme.orange : .clear, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show \(option.title.lowercased()) results")
            }
        }
        .padding(5)
        .background(NukeTheme.abyss.opacity(0.82), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(NukeTheme.border.opacity(0.9), lineWidth: 1))
    }

    private var unitConsole: some View {
        ZStack(alignment: .bottomLeading) {
            Image("CommandCenterHero")
                .resizable()
                .scaledToFill()
                .frame(height: 215)
                .clipped()
                .opacity(0.28)
            LinearGradient(
                colors: [NukeTheme.abyss.opacity(0.25), NukeTheme.abyss.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [NukeTheme.cyan.opacity(0.20), .clear],
                center: .bottomTrailing,
                startRadius: 5,
                endRadius: 250
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("NET UNITS", systemImage: "bolt.horizontal.circle.fill")
                        .font(.caption.weight(.heavy))
                        .tracking(1.1)
                        .foregroundStyle(NukeTheme.cyan)
                    Spacer()
                    NukeStatusPill(
                        title: summary.netUnits >= 0 ? "Signal positive" : "Review tape",
                        color: performanceColor,
                        symbol: summary.netUnits >= 0 ? "arrow.up.right" : "arrow.down.right"
                    )
                }
                Text(summary.netUnits.unitText)
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(performanceColor)
                    .shadow(color: performanceColor.opacity(0.38), radius: 12)
                HStack(spacing: 8) {
                    Text("\(summary.netUnits * profile.unitValue, format: .currency(code: "USD"))")
                    Text("|")
                    Text("\(summary.record.label) RECORD")
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.78))
            }
            .padding(17)
        }
        .frame(height: 215)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(NukeTheme.cyan.opacity(0.46), lineWidth: 1.2))
        .shadow(color: NukeTheme.cyan.opacity(0.12), radius: 18, y: 7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Net units \(summary.netUnits.unitText), \(summary.record.label) record")
    }

    private var metricGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 3), spacing: 9) {
            CommandMetric(label: "RECORD", value: summary.record.label, detail: "W-L-P", symbol: "checklist", color: NukeTheme.cyan)
            CommandMetric(label: "WIN RATE", value: summary.winRate.formatted(.percent.precision(.fractionLength(1))), detail: "SETTLED BETS", symbol: "scope", color: NukeTheme.green)
            CommandMetric(label: "STREAK", value: summary.streak, detail: "CURRENT RUN", symbol: "flame.fill", color: NukeTheme.ember)
        }
    }

    private var recentBets: some View {
        VStack(alignment: .leading, spacing: 10) {
            NukeSectionHeader(eyebrow: "Tracker", title: "Recent bets", actionTitle: "LAST 5")
            NukeCard {
                VStack(spacing: 0) {
                    ForEach(Array(bets.prefix(5))) { bet in
                        BetRow(bet: bet)
                        if bet.id != bets.prefix(5).last?.id { Divider().overlay(NukeTheme.border) }
                    }
                    if bets.isEmpty {
                        ContentUnavailableView(
                            "Your ledger is clear",
                            systemImage: "plus.circle.fill",
                            description: Text("Hit LOG below to record your first bet in seconds.")
                        )
                        .frame(height: 130)
                    }
                }
            }
        }
    }
}

private struct CommandMetric: View {
    let label: String
    let value: String
    let detail: String
    let symbol: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.black))
                .foregroundStyle(color)
                .frame(width: 29, height: 29)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(label)
                .font(.caption2.weight(.heavy))
                .tracking(0.7)
                .foregroundStyle(NukeTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
            Text(detail)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(color.opacity(0.88))
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(NukeTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(NukeTheme.border.opacity(0.92), lineWidth: 1))
    }
}

private struct UnitsChart: View {
    let bets: [Bet]
    let netUnits: Double

    var body: some View {
        NukeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("CUMULATIVE UNITS")
                            .font(.caption.weight(.heavy))
                            .tracking(1)
                            .foregroundStyle(NukeTheme.muted)
                        Text("YOUR EQUITY CURVE")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(NukeTheme.cyan)
                    }
                    Spacer()
                    Text(netUnits.unitText)
                        .font(.headline.weight(.black))
                        .monospacedDigit()
                        .foregroundStyle(netUnits >= 0 ? NukeTheme.green : NukeTheme.red)
                }
                let points = StatisticsService.cumulativePoints(for: bets.filter { $0.result != .pending })
                if points.isEmpty {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(NukeTheme.abyss.opacity(0.55))
                        VStack(spacing: 8) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.title2.weight(.black))
                                .foregroundStyle(NukeTheme.cyan)
                            Text("Your first settled bet powers the curve.")
                                .font(.caption)
                                .foregroundStyle(NukeTheme.muted)
                        }
                    }
                    .frame(height: 170)
                } else {
                    Chart(points, id: \.0) { point in
                        AreaMark(x: .value("Date", point.0), y: .value("Units", point.1))
                            .foregroundStyle(LinearGradient(colors: [NukeTheme.cyan.opacity(0.32), .clear], startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.catmullRom)
                        LineMark(x: .value("Date", point.0), y: .value("Units", point.1))
                            .foregroundStyle(NukeTheme.cyan)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                            .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 170)
                    .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
                    .chartYAxis { AxisMarks(position: .leading) }
                }
            }
        }
    }
}
