import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    let profile: UserProfile
    @Query(sort: \Bet.placedAt, order: .reverse) private var bets: [Bet]
    @State private var period: Period = .month
    @State private var isShowingFeed = false
    @ScaledMetric(relativeTo: .title) private var brandMarkSize = 38
    @ScaledMetric(relativeTo: .largeTitle) private var netUnitsFontSize = 48

    private var filtered: [Bet] { StatisticsService.filtered(bets, period: period) }
    private var summary: DashboardSummary { StatisticsService.summary(for: filtered) }
    private var performanceColor: Color { summary.netUnits >= 0 ? NukeTheme.green : NukeTheme.red }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                commandHeader
                periodRail
                unitConsole
                metricGrid
                UnitsChart(bets: filtered, netUnits: summary.netUnits)
                FreePicksPreview { isShowingFeed = true }
                recentBets
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .sheet(isPresented: $isShowingFeed) {
            NavigationStack {
                FreePicksView()
            }
        }
    }

    private var commandHeader: some View {
        ViewThatFits(in: .horizontal) {
            commandHeaderRow
            VStack(alignment: .leading, spacing: 10) {
                brandIdentity
                HStack {
                    Spacer()
                    liveStatus
                }
            }
        }
    }

    private var commandHeaderRow: some View {
        HStack(spacing: 11) {
            brandIdentity

            Spacer(minLength: 8)

            liveStatus
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var brandIdentity: some View {
        HStack(spacing: 11) {
            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: brandMarkSize, height: brandMarkSize)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(NukeTheme.orange.opacity(0.6), lineWidth: 1))

            VStack(alignment: .leading, spacing: 2) {
                Text("NUKE")
                    .font(.title3.weight(.black))
                    .tracking(1.5)
                Text("COMMAND CENTER")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.05)
                    .foregroundStyle(NukeTheme.orange)
            }
        }
    }

    private var liveStatus: some View {
        NukeStatusPill(title: "Live", color: NukeTheme.cyan, symbol: "bolt.fill")
            .fixedSize(horizontal: true, vertical: false)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Label("NET UNITS", systemImage: "bolt.horizontal.circle.fill")
                    .font(.caption.weight(.heavy))
                    .tracking(1.1)
                    .foregroundStyle(NukeTheme.cyan)
                Spacer(minLength: 8)
                NukeStatusPill(
                    title: summary.netUnits >= 0 ? "Signal positive" : "Review tape",
                    color: performanceColor,
                    symbol: summary.netUnits >= 0 ? "arrow.up.right" : "arrow.down.right"
                )
                .fixedSize(horizontal: true, vertical: false)
            }
            ViewThatFits(in: .horizontal) {
                unitValueText(font: .system(size: netUnitsFontSize, weight: .black, design: .rounded))
                unitValueText(font: .largeTitle.weight(.black))
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
            .font(.caption.weight(.bold))
            .foregroundStyle(.white.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background { unitConsoleBackdrop }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(NukeTheme.cyan.opacity(0.46), lineWidth: 1.2))
        .shadow(color: NukeTheme.cyan.opacity(0.12), radius: 18, y: 7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Net units \(summary.netUnits.unitText), \(summary.record.label) record")
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 148), spacing: 10)], spacing: 10) {
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

    private func unitValueText(font: Font) -> some View {
        Text(summary.netUnits.unitText)
            .font(font)
            .monospacedDigit()
            .foregroundStyle(performanceColor)
            .shadow(color: performanceColor.opacity(0.38), radius: 12)
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
                .font(.caption2.weight(.heavy))
                .tracking(0.7)
                .foregroundStyle(NukeTheme.muted)
                .lineLimit(2)
            Text(value)
                .font(.headline.weight(.black))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(detail)
                .font(.caption2.weight(.bold))
                .tracking(0.5)
                .foregroundStyle(color.opacity(0.88))
                .lineLimit(2)
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

    private var points: [(Date, Double)] {
        StatisticsService.cumulativePoints(for: bets.filter { $0.result != .pending })
    }

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
                chartPlot
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1.8, contentMode: .fit)
            }
        }
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
                    .foregroundStyle(LinearGradient(colors: [NukeTheme.cyan.opacity(0.32), .clear], startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.catmullRom)
                LineMark(x: .value("Date", point.0), y: .value("Units", point.1))
                    .foregroundStyle(NukeTheme.cyan)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
            }
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
            .chartYAxis { AxisMarks(position: .leading) }
        }
    }
}
