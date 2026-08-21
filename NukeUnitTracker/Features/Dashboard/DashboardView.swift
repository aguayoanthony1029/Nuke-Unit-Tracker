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
                    Picker("Range", selection: $period) {
                        ForEach(Period.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    hero
                    metrics
                    UnitsChart(bets: filtered)
                    FreePicksPreview { isShowingFeed = true }
                    recentBets
                }
                .padding()
                .padding(.bottom, 18)
            }
            .background(NukeCommandBackdrop())
            .navigationDestination(isPresented: $isShowingFeed) { FreePicksView() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    Image("BrandMark")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        Text("NUKE").font(.headline.bold()).tracking(2)
                        Text("COMMAND CENTER").font(.caption2.bold()).foregroundStyle(NukeTheme.orange).tracking(1)
                    }
                }
                Spacer()
                Text("Hi, \(profile.displayName)")
                    .font(.subheadline)
                    .foregroundStyle(NukeTheme.muted)
            }
            HStack(spacing: 8) {
                NavigationLink {
                    TailBoardView()
                } label: {
                    Label("Tail Board", systemImage: "scope")
                }
                .font(.caption.weight(.heavy))
                .foregroundStyle(NukeTheme.cyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(NukeTheme.cyan.opacity(0.11), in: Capsule())

                if NukeFeatureFlags.vaultVerificationEnabled {
                    NavigationLink {
                        NukeVaultView(profile: profile)
                    } label: {
                        Label("Vault", systemImage: "lock.fill")
                    }
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(NukeTheme.ember)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(NukeTheme.ember.opacity(0.11), in: Capsule())
                }
            }
        }
    }

    private var hero: some View {
        NukeCard {
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("NET UNITS - \(period.title.uppercased())")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NukeTheme.muted)
                    Spacer()
                    NukeStatusPill(
                        title: summary.netUnits >= 0 ? "Signal positive" : "Review tape",
                        color: summary.netUnits >= 0 ? NukeTheme.green : NukeTheme.red
                    )
                }
                Text(summary.netUnits.unitText)
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(summary.netUnits >= 0 ? NukeTheme.green : NukeTheme.red)
                Text("\(summary.netUnits * profile.unitValue, format: .currency(code: "USD")) | \(summary.record.label) record")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
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
        NukeCard {
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.caption2.weight(.bold)).foregroundStyle(NukeTheme.muted)
                Text(format.format(value)).font(.title3.bold()).foregroundStyle(color)
            }
        }
    }

    private func metric(_ title: String, _ value: String, color: Color) -> some View {
        NukeCard {
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.caption2.weight(.bold)).foregroundStyle(NukeTheme.muted)
                Text(value).font(.title3.bold()).foregroundStyle(color)
            }
        }
    }

    private var recentBets: some View {
        VStack(alignment: .leading, spacing: 10) {
            NukeSectionHeader(eyebrow: "Tracker", title: "Recent bets", actionTitle: "Last 5")
            NukeCard {
                VStack(spacing: 0) {
                    ForEach(Array(bets.prefix(5))) { bet in
                        BetRow(bet: bet)
                        if bet.id != bets.prefix(5).last?.id { Divider().overlay(NukeTheme.border) }
                    }
                    if bets.isEmpty {
                        ContentUnavailableView("No bets logged", systemImage: "plus.circle", description: Text("Use the orange plus button to log your first play."))
                            .frame(height: 118)
                    }
                }
            }
        }
    }
}

private struct UnitsChart: View {
    let bets: [Bet]

    var body: some View {
        NukeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("UNITS TREND").font(.caption.weight(.bold)).foregroundStyle(NukeTheme.muted)
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis").foregroundStyle(NukeTheme.cyan)
                }
                let points = StatisticsService.cumulativePoints(for: bets.filter { $0.result != .pending })
                if points.isEmpty {
                    ContentUnavailableView("Log a bet to see your trend", systemImage: "chart.line.uptrend.xyaxis")
                        .frame(height: 150)
                } else {
                    Chart(points, id: \.0) { point in
                        LineMark(x: .value("Date", point.0), y: .value("Units", point.1))
                            .foregroundStyle(NukeTheme.cyan)
                            .interpolationMethod(.catmullRom)
                        AreaMark(x: .value("Date", point.0), y: .value("Units", point.1))
                            .foregroundStyle(NukeTheme.cyan.opacity(0.14))
                            .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 175)
                    .chartYAxis { AxisMarks(position: .leading) }
                }
            }
        }
    }
}
