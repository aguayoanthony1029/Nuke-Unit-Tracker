import SwiftUI
import SwiftData
import PhotosUI

struct AddBetView: View {
    private static let sportsbookCatalog = [
        "1xBet",
        "Bally Bet",
        "bet365",
        "BetMGM",
        "BetOnline",
        "betParx",
        "Betr",
        "BetRivers",
        "Borgata Sportsbook",
        "Bovada",
        "Caesars Sportsbook",
        "Circa Sports",
        "Desert Diamond Sports",
        "DraftKings",
        "ESPN Bet",
        "Fanatics Sportsbook",
        "FanDuel",
        "Fliff",
        "Hard Rock Bet",
        "Pinnacle",
        "PrizePicks",
        "Stake",
        "SuperBook Sports",
        "theScore Bet",
        "TwinSpires",
        "Underdog Fantasy"
    ]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var existingAttachments: [SlipAttachment]
    let editing: Bet?
    @State private var title = ""
    @State private var sport = "NBA"
    @State private var league = ""
    @State private var sportsbook = ""
    @State private var kind: BetKind = .straight
    @State private var oddsFormat: OddsFormat = .american
    @State private var oddsText = "-110"
    @State private var risk = 1.0
    @State private var result: BetResult = .pending
    @State private var placedAt = Date()
    @State private var notes = ""
    @State private var legsText = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var errorMessage: String?

    init(editing: Bet? = nil) {
        self.editing = editing
        let betID = editing?.id ?? UUID()
        _existingAttachments = Query(filter: #Predicate<SlipAttachment> { $0.betID == betID })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("BET") {
                    TextField("Matchup or selection", text: $title)
                    Picker("Type", selection: $kind) { ForEach(BetKind.allCases) { Text($0.label).tag($0) } }
                    Picker("Sport", selection: $sport) { ForEach(["NBA", "NFL", "MLB", "NHL", "NCAAB", "Soccer", "Other"], id: \.self) { Text($0) } }
                    TextField("League (optional)", text: $league)
                    Picker("Sportsbook", selection: $sportsbook) {
                        Text("None").tag("")
                        ForEach(sportsbookOptions, id: \.self) { book in
                            Text(book).tag(book)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section("ODDS & STAKE") {
                    Picker("Format", selection: $oddsFormat) { ForEach(OddsFormat.allCases) { Text($0.label).tag($0) } }.pickerStyle(.segmented)
                    TextField(oddsFormat == .american ? "-110" : "1.91", text: $oddsText).keyboardType(.numbersAndPunctuation)
                    HStack { Text("Risk units"); Spacer(); TextField("1.00", value: $risk, format: .number.precision(.fractionLength(2))).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    HStack { quickUnit(0.5); quickUnit(1); quickUnit(2); quickUnit(3) }
                    calculationPreview
                }
                if kind != .straight { Section("PARLAY LEGS") { TextEditor(text: $legsText).frame(minHeight: 90); Text("One leg per line. Overall parlay odds remain the source of truth.").font(.caption).foregroundStyle(NukeTheme.muted) } }
                Section("RESULT") { Picker("Status", selection: $result) { ForEach(BetResult.allCases) { Text($0.label).tag($0) } }.pickerStyle(.segmented); DatePicker("Date", selection: $placedAt) }
                Section("SLIP PHOTOS") { PhotosPicker(selection: $selectedPhotos, maxSelectionCount: max(0, 3 - existingAttachmentCount), matching: .images) { Label("Add up to 3 photos", systemImage: "photo.on.rectangle") }; Text("Photos are compressed for fast private sync.").font(.caption).foregroundStyle(NukeTheme.muted) }
                Section("NOTES") { TextEditor(text: $notes).frame(minHeight: 70) }
            }
            .scrollContentBackground(.hidden).background(NukeTheme.background)
            .navigationTitle(editing == nil ? "New Bet" : "Edit Bet")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Double(oddsText) == nil || risk <= 0) } }
            .task { hydrateIfEditing() }
            .alert("Couldn’t save photo", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) { Button("OK", role: .cancel) {} } message: { Text(errorMessage ?? "") }
        }
    }

    private var existingAttachmentCount: Int { existingAttachments.count }
    private var sportsbookOptions: [String] {
        guard !sportsbook.isEmpty, !Self.sportsbookCatalog.contains(sportsbook) else {
            return Self.sportsbookCatalog
        }
        return [sportsbook] + Self.sportsbookCatalog
    }
    private var decimalOdds: Double { OddsConverter.decimal(from: Double(oddsText) ?? -110, format: oddsFormat) }
    private var calculationPreview: some View { HStack { labelValue("RISK", risk.plainUnitText); labelValue("TO WIN", (risk * (decimalOdds - 1)).plainUnitText); labelValue("RETURN", (risk * decimalOdds).plainUnitText) }.padding(.vertical, 5) }
    private func labelValue(_ label: String, _ value: String) -> some View { VStack(alignment: .leading) { Text(label).font(.caption2).foregroundStyle(NukeTheme.cyan); Text(value).font(.headline) }.frame(maxWidth: .infinity, alignment: .leading) }
    private func quickUnit(_ value: Double) -> some View { Button("\(value, specifier: "%g")u") { risk = value }.buttonStyle(.bordered).tint(risk == value ? NukeTheme.orange : NukeTheme.muted) }

    private func hydrateIfEditing() {
        guard let bet = editing, title.isEmpty else { return }
        title = bet.title; sport = bet.sport; league = bet.league; sportsbook = bet.sportsbook; kind = bet.kind; oddsFormat = bet.oddsFormatRaw == OddsFormat.decimal.rawValue ? .decimal : .american; oddsText = String(format: oddsFormat == .american ? "%.0f" : "%.2f", bet.oddsInput); risk = bet.riskUnits; result = bet.result; placedAt = bet.placedAt; notes = bet.notes
    }

    private func save() {
        let odds = Double(oddsText) ?? -110
        let bet = editing ?? Bet(title: title, sport: sport, league: league, sportsbook: sportsbook, kind: kind, oddsInput: odds, oddsFormat: oddsFormat, riskUnits: risk, result: result, placedAt: placedAt, notes: notes)
        if editing != nil { bet.title = title; bet.sport = sport; bet.league = league; bet.sportsbook = sportsbook; bet.kindRaw = kind.rawValue; bet.oddsInput = odds; bet.oddsFormatRaw = oddsFormat.rawValue; bet.oddsDecimal = decimalOdds; bet.riskUnits = risk; bet.resultRaw = result.rawValue; bet.placedAt = placedAt; bet.settledAt = result == .pending ? nil : (bet.settledAt ?? .now); bet.notes = notes; bet.updatedAt = .now } else { modelContext.insert(bet) }
        let betID = bet.id
        let oldLegs = try? modelContext.fetch(FetchDescriptor<BetLeg>(predicate: #Predicate { $0.betID == betID }))
        oldLegs?.forEach(modelContext.delete)
        legsText.split(separator: "\n").map(String.init).enumerated().filter { !$0.element.trimmingCharacters(in: .whitespaces).isEmpty }.forEach { modelContext.insert(BetLeg(betID: bet.id, selection: $0.element, position: $0.offset)) }
        Task { await savePhotos(for: bet) }
        try? modelContext.save()
        dismiss()
    }

    private func savePhotos(for bet: Bet) async {
        for item in selectedPhotos.prefix(3) {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                let attachment = try SlipAttachmentStore.shared.save(imageData: data, for: bet.id)
                modelContext.insert(attachment)
                do { attachment.cloudRecordName = try await SlipAttachmentStore.shared.uploadToPrivateCloud(attachment) } catch { /* local save remains durable; retry can run on next launch */ }
            } catch { errorMessage = error.localizedDescription }
        }
        try? modelContext.save()
    }
}
