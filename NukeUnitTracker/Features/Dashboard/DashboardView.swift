import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    let profile: UserProfile
    @Query(sort: \Bet.placedAt, order: .reverse) private var bets: [Bet]
    @State private var period: Period = .month
    @State private var isShowingCommunity = false
    @ScaledMetric(relativeTo: .title) private var brandMarkSize = 38
    @ScaledMetric(relativeTo: .largeTitle) private var netUnitsFontSize = 48

    private var filtered: [Bet] { StatisticsService.filtered(bets, period: period) }
    private var summary: DashboardSummary { StatisticsService.summary(for: filtered) }
    private var performanceColor: Color {
        if summary.netUnits > 0 { return NukeTheme.matrixGreen }
        if summary.netUnits < 0 { return NukeTheme.alertRed }
        return NukeTheme.hudCyan
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                commandHeader
                periodRail
                unitConsole
                metricGrid
                UnitsChart(bets: filtered, netUnits: summary.netUnits)
                recentBets
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(NukeTheme.bgBase.ignoresSafeArea())
        .sheet(isPresented: $isShowingCommunity) {
            NavigationStack {
                NukeCommunityView()
            }
        }
    }

    private var commandHeader: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 11) {
                brandIdentity
                    .layoutPriority(1)
                Spacer(minLength: 8)
                communityButton
            }

            HStack(spacing: 10) {
                brandMark
                Text("NUKE")
                    .font(NukeTheme.titleFont(size: 21, relativeTo: .title3))
                    .tracking(1.2)
                    .lineLimit(1)
                Spacer(minLength: 6)
                communityButton
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var brandIdentity: some View {
        HStack(spacing: 11) {
            brandMark

            VStack(alignment: .leading, spacing: 2) {
                Text("NUKE")
                    .font(NukeTheme.titleFont(size: 24, relativeTo: .title3))
                    .tracking(1.5)
                Text("COMMAND CENTER")
                    .font(NukeTheme.headerFont(size: 12, relativeTo: .caption2))
                    .tracking(1.05)
                    .foregroundStyle(NukeTheme.neonOrange)
            }
        }
    }

    private var brandMark: some View {
        Image("BrandMark")
            .resizable()
            .scaledToFit()
            .frame(width: brandMarkSize, height: brandMarkSize)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(NukeTheme.orange.opacity(0.6), lineWidth: 1))
    }

    private var communityButton: some View {
        Button {
            isShowingCommunity = true
        } label: {
            NukeStatusPill(title: "Join the Community", color: NukeTheme.neonOrange, symbol: "person.3.fill")
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Join the Nuke Sports Bets Community")
        .fixedSize(horizontal: true, vertical: true)
    }

    private var periodRail: some View {
        HStack(spacing: 5) {
            ForEach(Period.allCases) { option in
                Button {
                    withAnimation(.snappy(duration: 0.22)) { period = option }
                } label: {
                    Text(option.title.uppercased())
                        .font(NukeTheme.headerFont(size: 13, relativeTo: .caption))
                        .tracking(0.75)
                        .foregroundStyle(period == option ? .black : Color.white.opacity(0.50))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(period == option ? NukeTheme.neonOrange : .clear, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show \(option.title.lowercased()) results")
            }
        }
        .padding(5)
        .tacticalCard()
    }

    private var unitConsole: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Label("NET UNITS", systemImage: "bolt.horizontal.circle.fill")
                    .font(NukeTheme.headerFont(size: 13, relativeTo: .caption))
                    .tracking(1.1)
                    .foregroundStyle(Color.white.opacity(0.50))
                Spacer(minLength: 8)
                NukeStatusPill(
                    title: summary.netUnits >= 0 ? "Positive" : "Negative",
                    color: performanceColor,
                    symbol: summary.netUnits >= 0 ? "arrow.up.right" : "arrow.down.right"
                )
                .fixedSize(horizontal: true, vertical: false)
            }
            ViewThatFits(in: .horizontal) {
                unitValueText(size: netUnitsFontSize)
                unitValueText(size: 34)
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    Text("\(summary.netUnits * profile.unitValue, format: .currency(code: "USD"))")
                    Text("|")
                    Text("\(summary.record.label) RECORD")
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(summary.netUnits * profile.unitValue, format: .currency(code: "USD"))")
                    Text("\(summary.record.label) RECORD")
                }
            }
            .font(NukeTheme.headerFont(size: 13, relativeTo: .caption))
            .foregroundStyle(.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background { unitConsoleBackdrop }
        .tacticalCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Net units \(summary.netUnits.unitText), \(summary.record.label) record")
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 148), spacing: 10)], spacing: 10) {
            CommandMetric(label: "RECORD", value: summary.record.label, detail: "W-L-P", symbol: "checklist", color: NukeTheme.hudCyan)
            CommandMetric(label: "WIN RATE", value: summary.winRate.formatted(.percent.precision(.fractionLength(1))), detail: "SETTLED BETS", symbol: "scope", color: NukeTheme.matrixGreen)
            CommandMetric(label: "STREAK", value: summary.streak, detail: "CURRENT RUN", symbol: "flame.fill", color: NukeTheme.neonOrange)
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
                        .padding(.vertical, 28)
                    }
                }
            }
        }
    }

    private var unitConsoleBackdrop: some View {
        GeometryReader { proxy in
            ZStack {
                Image("CommandCenterHero")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
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
                    endRadius: max(proxy.size.width, proxy.size.height)
                )
            }
        }
    }

    private func unitValueText(size: CGFloat) -> some View {
        Text(summary.netUnits.unitText)
            .font(NukeTheme.dataFont(size: size, relativeTo: .largeTitle))
            .monospacedDigit()
            .foregroundStyle(performanceColor)
            .neonGlow(color: performanceColor)
            .lineLimit(1)
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
                .font(NukeTheme.headerFont(size: 12, relativeTo: .caption2))
                .tracking(0.7)
                .foregroundStyle(Color.white.opacity(0.50))
                .lineLimit(2)
            Text(value)
                .font(NukeTheme.dataFont(size: 23, relativeTo: .headline))
                .monospacedDigit()
                .foregroundStyle(color)
                .neonGlow(color: color)
                .lineLimit(1)
            Text(detail)
                .font(NukeTheme.headerFont(size: 11, relativeTo: .caption2))
                .tracking(0.5)
                .foregroundStyle(color.opacity(0.88))
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .tacticalCard()
    }
}

private struct UnitsChart: View {
    let bets: [Bet]
    let netUnits: Double

    private var netUnitsColor: Color {
        if netUnits > 0 { return NukeTheme.matrixGreen }
        if netUnits < 0 { return NukeTheme.alertRed }
        return NukeTheme.hudCyan
    }

    private var points: [(Date, Double)] {
        StatisticsService.cumulativePoints(for: bets.filter { $0.result != .pending })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("CUMULATIVE UNITS")
                            .font(NukeTheme.headerFont(size: 13, relativeTo: .caption))
                            .tracking(1)
                            .foregroundStyle(Color.white.opacity(0.50))
                        Text("YOUR EQUITY CURVE")
                            .font(NukeTheme.headerFont(size: 11, relativeTo: .caption2))
                            .foregroundStyle(NukeTheme.hudCyan)
                    }
                    Spacer()
                    Text(netUnits.unitText)
                        .font(NukeTheme.dataFont(size: 22, relativeTo: .headline))
                        .monospacedDigit()
                        .foregroundStyle(netUnitsColor)
                        .neonGlow(color: netUnitsColor)
                }
                chartPlot
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.8, contentMode: .fit)
            }
        .padding(16)
        .tacticalCard()
    }

    @ViewBuilder
    private var chartPlot: some View {
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
                        .multilineTextAlignment(.center)
                }
            }
        } else {
            Chart(points, id: \.0) { point in
                AreaMark(x: .value("Date", point.0), y: .value("Units", point.1))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [NukeTheme.hudCyan.opacity(0.24), NukeTheme.hudCyan.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                LineMark(x: .value("Date", point.0), y: .value("Units", point.1))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [NukeTheme.hudCyan.opacity(0.50), NukeTheme.hudCyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                    .shadow(color: NukeTheme.hudCyan.opacity(0.82), radius: 4)
                    .shadow(color: NukeTheme.hudCyan.opacity(0.36), radius: 10)

                PointMark(x: .value("Date", point.0), y: .value("Units", point.1))
                    .foregroundStyle(Color.white)
                    .symbolSize(18)
                    .shadow(color: NukeTheme.hudCyan.opacity(0.95), radius: 3)
                    .shadow(color: NukeTheme.hudCyan.opacity(0.42), radius: 8)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 6]))
                        .foregroundStyle(Color.white.opacity(0.05))
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.16))
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.48))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 6]))
                        .foregroundStyle(Color.white.opacity(0.05))
                    AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.white.opacity(0.16))
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.48))
                }
            }
        }
    }

}
