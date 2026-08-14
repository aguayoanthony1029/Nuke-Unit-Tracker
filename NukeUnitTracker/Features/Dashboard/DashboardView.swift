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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    Picker("Range", selection: $period) { ForEach(Period.allCases) { Text($0.title).tag($0) } }
                        .pickerStyle(.segmented)
                    hero
                    metrics
                    UnitsChart(bets: filtered)
                    FreePicksPreview { isShowingFeed = true }
                    recentBets
                }
                .padding()
            }
            .background(NukeTheme.background)
            .navigationDestination(isPresented: $isShowingFeed) { FreePicksView() }
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                Image("BrandMark").resizable().scaledToFill().frame(width: 38, height: 38).clipShape(Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text("NUKE").font(.headline.bold()).tracking(2)
                    Text("SPORTS BETS").font(.caption2.bold()).foregroundStyle(NukeTheme.orange)
                }
            }
            Spacer()
            Text("Hi, \(profile.displayName)").font(.subheadline).foregroundStyle(NukeTheme.muted)
        }
    }

    private var hero: some View {
        NukeCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("NET UNITS — \(period.title.uppercased())").font(.caption.weight(.semibold)).foregroundStyle(NukeTheme.muted)
                Text(summary.netUnits.unitText).font(.system(size: 42, weight: .heavy, design: .rounded)).foregroundStyle(summary.netUnits >= 0 ? NukeTheme.green : NukeTheme.red)
                Text("\(summary.netUnits * profile.unitValue, format: .currency(code: "USD")) • \(summary.record.label) record")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var metrics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            metric("WIN RATE", summary.winRate, format: .percent.precision(.fractionLength(1)), color: NukeTheme.cyan)
            metric("STREAK", summary.streak, color: NukeTheme.green)
            metric("PENDING", summary.pendingExposure.plainUnitText, color: NukeTheme.orange)
            metric("ROI", summary.roi, format: .percent.precision(.fractionLength(1)), color: NukeTheme.cyan)
        }
    }

    private func metric<F: FormatStyle>(_ title: String, _ value: F.FormatInput, format: F, color: Color) -> some View where F.FormatOutput == String {
        NukeCard { VStack(alignment: .leading, spacing: 5) { Text(title).font(.caption2.weight(.bold)).foregroundStyle(NukeTheme.muted); Text(value, format: format).font(.title3.bold()).foregroundStyle(color) } }
    }
    private func metric(_ title: String, _ value: String, color: Color) -> some View {
        NukeCard { VStack(alignment: .leading, spacing: 5) { Text(title).font(.caption2.weight(.bold)).foregroundStyle(NukeTheme.muted); Text(value).font(.title3.bold()).foregroundStyle(color) } }
    }

    private var recentBets: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Text("RECENT BETS").font(.headline); Spacer(); Text("Last 5").font(.caption).foregroundStyle(NukeTheme.cyan) }
            NukeCard { VStack(spacing: 0) { ForEach(Array(bets.prefix(5))) { bet in BetRow(bet: bet); if bet.id != bets.prefix(5).last?.id { Divider().overlay(NukeTheme.border) } } } }
        }
    }
}

private struct UnitsChart: View {
    let bets: [Bet]
    var body: some View {
        NukeCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("UNITS TREND").font(.caption.weight(.bold)).foregroundStyle(NukeTheme.muted)
                let points = StatisticsService.cumulativePoints(for: bets.filter { $0.result != .pending })
                if points.isEmpty { ContentUnavailableView("Log a bet to see your trend", systemImage: "chart.line.uptrend.xyaxis") .frame(height: 150) }
                else { Chart(points, id: \.0) { point in LineMark(x: .value("Date", point.0), y: .value("Units", point.1)).foregroundStyle(NukeTheme.cyan).interpolationMethod(.catmullRom); AreaMark(x: .value("Date", point.0), y: .value("Units", point.1)).foregroundStyle(NukeTheme.cyan.opacity(0.14)).interpolationMethod(.catmullRom) }.frame(height: 175).chartYAxis { AxisMarks(position: .leading) } }
            }
        }
    }
}

