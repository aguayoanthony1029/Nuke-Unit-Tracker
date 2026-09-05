import SwiftUI
import SwiftData

struct BetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bet.placedAt, order: .reverse) private var bets: [Bet]
    @State private var search = ""
    @State private var selectedSport = "All"
    @State private var selectedResult = "All"
    @State private var selectedSportsbook = "All"
    @State private var selectedRange: HistoryRange = .allTime
    @State private var exportItem: ExportItem?
    @State private var betToDelete: Bet?
    @State private var operationError: String?

    private var shownBets: [Bet] {
        bets.filter { bet in
            (selectedSport == "All" || bet.sport == selectedSport) &&
            (selectedResult == "All" || bet.resultRaw == selectedResult.lowercased()) &&
            (selectedSportsbook == "All" ||
             (selectedSportsbook == "No sportsbook" ? bet.sportsbook.isEmpty : bet.sportsbook == selectedSportsbook)) &&
            selectedRange.contains(bet.placedAt) &&
            (search.isEmpty || bet.title.localizedCaseInsensitiveContains(search) || bet.sportsbook.localizedCaseInsensitiveContains(search))
        }
    }
    private var sports: [String] { ["All"] + Array(Set(bets.map(\.sport))).sorted() }
    private var sportsbooks: [String] { ["All", "No sportsbook"] + Array(Set(bets.map(\.sportsbook).filter { !$0.isEmpty })).sorted() }

    var body: some View {
        NavigationStack {
            List {
                if shownBets.isEmpty {
                    ContentUnavailableView(
                        bets.isEmpty ? "No tracked bets" : "No matching bets",
                        systemImage: bets.isEmpty ? "list.bullet.clipboard" : "line.3.horizontal.decrease.circle",
                        description: Text(bets.isEmpty
                                          ? "Use the LOG button to add your first bet."
                                          : "Try changing your search or filters.")
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                ForEach(groupedBets, id: \.key) { day, dayBets in
                    Section(day.formatted(date: .abbreviated, time: .omitted).uppercased()) {
                        ForEach(dayBets) { bet in
                            NavigationLink { BetDetailView(bet: bet) } label: { BetRow(bet: bet) }
                                .listRowBackground(NukeTheme.surface)
                                .swipeActions { Button("Delete", role: .destructive) { betToDelete = bet } }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden).background(NukeTheme.background)
            .navigationTitle("All Bets")
            .searchable(text: $search, prompt: "Search bet or book")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Export") { export() }
                        .disabled(shownBets.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sport", selection: $selectedSport) {
                            ForEach(sports, id: \.self) { Text($0) }
                        }
                        Picker("Result", selection: $selectedResult) {
                            ForEach(["All"] + BetResult.allCases.map(\.label), id: \.self) { Text($0) }
                        }
                        Picker("Sportsbook", selection: $selectedSportsbook) {
                            ForEach(sportsbooks, id: \.self) { Text($0) }
                        }
                        Picker("Date range", selection: $selectedRange) {
                            ForEach(HistoryRange.allCases) { Text($0.label).tag($0) }
                        }
                        if hasActiveFilters {
                            Divider()
                            Button("Clear filters") { clearFilters() }
                        }
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filter bets")
                }
            }
            .sheet(item: $exportItem) { item in ShareSheet(url: item.url) }
            .confirmationDialog("Delete this bet?", isPresented: Binding(get: { betToDelete != nil }, set: { if !$0 { betToDelete = nil } }), titleVisibility: .visible) {
                Button("Delete", role: .destructive) { if let betToDelete { delete(betToDelete); self.betToDelete = nil } }
                Button("Cancel", role: .cancel) { betToDelete = nil }
            } message: { Text("This removes the bet, its legs, and its local slip-photo records.") }
            .alert("Couldn’t Complete Action", isPresented: Binding(
                get: { operationError != nil },
                set: { if !$0 { operationError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(operationError ?? "")
            }
        }
    }

    private var groupedBets: [(key: Date, value: [Bet])] {
        Dictionary(grouping: shownBets) { Calendar.current.startOfDay(for: $0.placedAt) }.sorted { $0.key > $1.key }
    }

    private var hasActiveFilters: Bool {
        selectedSport != "All" || selectedResult != "All" || selectedSportsbook != "All" || selectedRange != .allTime
    }

    private func clearFilters() {
        selectedSport = "All"
        selectedResult = "All"
        selectedSportsbook = "All"
        selectedRange = .allTime
    }

    private func export() {
        do {
            exportItem = ExportItem(url: try ExportService.writeCSV(bets: shownBets))
        } catch {
            operationError = "The CSV file could not be created. \(error.localizedDescription)"
        }
    }

    private func delete(_ bet: Bet) {
        let id = bet.id
        do {
            let legs = try modelContext.fetch(FetchDescriptor<BetLeg>(predicate: #Predicate { $0.betID == id }))
            let attachments = try modelContext.fetch(FetchDescriptor<SlipAttachment>(predicate: #Predicate { $0.betID == id }))
            let attachmentPaths = attachments.map(\.localRelativePath)
            attachments.forEach(modelContext.delete)
            legs.forEach(modelContext.delete)
            modelContext.delete(bet)
            try modelContext.save()
            attachmentPaths.forEach { SlipAttachmentStore.shared.removeLocalFile(relativePath: $0) }
        } catch {
            modelContext.rollback()
            operationError = "The bet could not be deleted. \(error.localizedDescription)"
        }
    }
}

private enum HistoryRange: String, CaseIterable, Identifiable {
    case allTime, today, thisWeek, thisMonth, thisYear

    var id: String { rawValue }

    var label: String {
        switch self {
        case .allTime: "All time"
        case .today: "Today"
        case .thisWeek: "This week"
        case .thisMonth: "This month"
        case .thisYear: "This year"
        }
    }

    func contains(_ date: Date, reference: Date = .now, calendar: Calendar = .current) -> Bool {
        switch self {
        case .allTime: true
        case .today: calendar.isDate(date, inSameDayAs: reference)
        case .thisWeek: calendar.isDate(date, equalTo: reference, toGranularity: .weekOfYear)
        case .thisMonth: calendar.isDate(date, equalTo: reference, toGranularity: .month)
        case .thisYear: calendar.isDate(date, equalTo: reference, toGranularity: .year)
        }
    }
}

struct BetRow: View {
    let bet: Bet
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: sportIcon).foregroundStyle(NukeTheme.orange).frame(width: 26, height: 26).background(NukeTheme.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 3) {
                Text(bet.title).font(.subheadline.bold()).lineLimit(1)
                Text("\(bet.sport) · \(formattedOdds) · \(bet.riskUnits.plainUnitText)\(bet.sportsbook.isEmpty ? "" : " · \(bet.sportsbook)")").font(.caption).foregroundStyle(NukeTheme.muted).lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(bet.result == .pending ? "Pending" : bet.profitUnits.unitText).font(.subheadline.bold()).foregroundStyle(resultColor)
                Text(bet.result.label.uppercased()).font(.caption2.bold()).padding(.horizontal, 6).padding(.vertical, 2).background(resultColor.opacity(0.16), in: Capsule()).foregroundStyle(resultColor)
            }
        }
        .padding(.vertical, 4)
    }
    private var formattedOdds: String { bet.oddsFormatRaw == OddsFormat.american.rawValue ? String(format: "%+.0f", bet.oddsInput) : String(format: "%.2f", bet.oddsInput) }
    private var sportIcon: String { BetCatalog.symbol(for: bet.sport) }
    private var resultColor: Color { switch bet.result { case .win: NukeTheme.green; case .loss: NukeTheme.red; case .pending: NukeTheme.orange; case .push, .void: NukeTheme.cyan } }
}

struct BetDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var legs: [BetLeg]
    @Query private var attachments: [SlipAttachment]
    let bet: Bet
    @State private var editing = false
    @State private var settlementError: String?

    init(bet: Bet) {
        self.bet = bet
        let id = bet.id
        _legs = Query(filter: #Predicate<BetLeg> { $0.betID == id }, sort: \BetLeg.position)
        _attachments = Query(filter: #Predicate<SlipAttachment> { $0.betID == id })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                NukeCard { VStack(alignment: .leading, spacing: 10) { Text(bet.title).font(.title2.bold()); Text(detailSubtitle).foregroundStyle(NukeTheme.muted); HStack { metric("RISK", bet.riskUnits.plainUnitText); metric("TO WIN", (bet.riskUnits * (bet.oddsDecimal - 1)).plainUnitText); metric("RETURN", bet.totalReturnUnits.plainUnitText) } } }
                if !legs.isEmpty { NukeCard { VStack(alignment: .leading) { Text("LEGS").font(.caption.bold()).foregroundStyle(NukeTheme.muted); ForEach(legs) { Text("• \($0.selection)") } } } }
                if !bet.notes.isEmpty { NukeCard { Text(bet.notes) } }
                if !attachments.isEmpty { ScrollView(.horizontal) { HStack { ForEach(attachments) { attachment in SlipImageView(attachment: attachment) } } } }
                if bet.result == .pending { settlementControls }
            }.padding()
        }
        .background(NukeTheme.background).navigationTitle("Bet Details").toolbar { Button("Edit") { editing = true } }
        .sheet(isPresented: $editing) { AddBetView(editing: bet) }
        .alert("Couldn’t Settle Bet", isPresented: Binding(
            get: { settlementError != nil },
            set: { if !$0 { settlementError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(settlementError ?? "")
        }
    }

    private var settlementControls: some View {
        NukeCard { VStack(alignment: .leading, spacing: 12) { Text("SETTLE BET").font(.caption.bold()).foregroundStyle(NukeTheme.muted); HStack { ForEach([BetResult.win, .loss, .push, .void]) { result in Button(result.label) { settle(as: result) }.buttonStyle(ResultButton(result: result)) } } } }
    }

    private var detailSubtitle: String {
        [bet.sport, bet.league, bet.kind.label, bet.sportsbook.isEmpty ? "No sportsbook" : bet.sportsbook]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    private func settle(as result: BetResult) {
        bet.resultRaw = result.rawValue
        bet.settledAt = .now
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            settlementError = error.localizedDescription
        }
    }

    private func metric(_ label: String, _ value: String) -> some View { VStack(alignment: .leading) { Text(label).font(.caption2).foregroundStyle(NukeTheme.muted); Text(value).font(.headline).foregroundStyle(NukeTheme.cyan) }.frame(maxWidth: .infinity, alignment: .leading) }
}

private struct SlipImageView: View {
    let attachment: SlipAttachment
    @State private var image: UIImage?
    var body: some View {
        Group {
            if let image { Image(uiImage: image).resizable().scaledToFill().frame(width: 170, height: 120).clipped() }
            else { ProgressView().frame(width: 170, height: 120) }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task { image = await SlipAttachmentStore.shared.imageForDisplay(for: attachment) }
    }
}

private struct ResultButton: ButtonStyle {
    let result: BetResult
    func makeBody(configuration: Configuration) -> some View { configuration.label.font(.caption.bold()).foregroundStyle(color).padding(.vertical, 9).frame(maxWidth: .infinity).background(color.opacity(configuration.isPressed ? 0.3 : 0.16), in: RoundedRectangle(cornerRadius: 8)) }
    private var color: Color { switch result { case .win: NukeTheme.green; case .loss: NukeTheme.red; case .push, .void: NukeTheme.cyan; case .pending: NukeTheme.orange } }
}

private struct ExportItem: Identifiable { let url: URL; var id: URL { url } }
private struct ShareSheet: View {
    let url: URL
    var body: some View { ShareLink(item: url) { Label("Share export", systemImage: "square.and.arrow.up") }.padding() }
}
