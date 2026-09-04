import SwiftUI
import SwiftData
import PhotosUI

struct AddBetView: View {
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
    @State private var slipToScan: PhotosPickerItem?
    @State private var isScanningSlip = false
    @State private var scanFeedback: String?
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var shouldDismissAfterAlert = false
    @State private var hasHydrated = false

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
                    Picker("Sport", selection: $sport) {
                        ForEach(BetCatalog.sports, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.menu)
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
                    Picker("Format", selection: oddsFormatBinding) { ForEach(OddsFormat.allCases) { Text($0.label).tag($0) } }.pickerStyle(.segmented)
                    TextField(oddsFormat == .american ? "-110" : "1.91", text: $oddsText).keyboardType(.numbersAndPunctuation)
                    if !oddsAreValid {
                        Text(oddsFormat == .american
                             ? "Enter American odds of -100 or lower, or +100 or higher."
                             : "Enter decimal odds greater than 1.00.")
                            .font(.caption)
                            .foregroundStyle(NukeTheme.red)
                    }
                    HStack { Text("Risk units"); Spacer(); TextField("1.00", value: $risk, format: .number.precision(.fractionLength(2))).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    if !riskIsValid {
                        Text("Risk units must be a number greater than zero.")
                            .font(.caption)
                            .foregroundStyle(NukeTheme.red)
                    }
                    HStack { quickUnit(0.5); quickUnit(1); quickUnit(2); quickUnit(3) }
                    calculationPreview
                }
                if kind != .straight { Section("PARLAY LEGS") { TextEditor(text: $legsText).frame(minHeight: 90); Text("One leg per line. Overall parlay odds remain the source of truth.").font(.caption).foregroundStyle(NukeTheme.muted) } }
                Section("RESULT") { Picker("Status", selection: $result) { ForEach(BetResult.allCases) { Text($0.label).tag($0) } }.pickerStyle(.segmented); DatePicker("Date", selection: $placedAt) }
                Section("SLIP PHOTOS") {
                    PhotosPicker(selection: $slipToScan, matching: .images) {
                        Label(isScanningSlip ? "Scanning slip…" : "Scan a slip to prefill", systemImage: "text.viewfinder")
                    }
                    .disabled(isSaving || isScanningSlip)
                    .accessibilityIdentifier("scan-slip-button")

                    if let scanFeedback {
                        Label(scanFeedback, systemImage: "checkmark.text.page")
                            .font(.caption)
                            .foregroundStyle(NukeTheme.muted)
                    }

                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: max(0, 3 - existingAttachmentCount), matching: .images) {
                        Label("Add up to 3 photos", systemImage: "photo.on.rectangle")
                    }
                    .disabled(isSaving || isScanningSlip)

                    Text("Scanning uses on-device text recognition. Nothing from a slip is sent to a server; review all prefilled details before saving.")
                        .font(.caption)
                        .foregroundStyle(NukeTheme.muted)
                }
                Section("NOTES") { TextEditor(text: $notes).frame(minHeight: 70) }
            }
            .scrollContentBackground(.hidden).background(NukeTheme.background)
            .navigationTitle(editing == nil ? "New Bet" : "Edit Bet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                            .accessibilityLabel("Saving bet")
                    } else {
                        Button("Save") {
                            Task { await save() }
                        }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !oddsAreValid || !riskIsValid)
                    }
                }
            }
            .task { hydrateForm() }
            .onChange(of: slipToScan) { _, item in
                guard let item else { return }
                Task { await scanSlip(item) }
            }
            .interactiveDismissDisabled(isSaving)
            .alert("Couldn’t finish saving", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) {
                    if shouldDismissAfterAlert { dismiss() }
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var existingAttachmentCount: Int { existingAttachments.count }
    private var oddsFormatBinding: Binding<OddsFormat> {
        Binding(
            get: { oddsFormat },
            set: { newFormat in
                let oldFormat = oddsFormat
                oddsFormat = newFormat
                convertOdds(from: oldFormat, to: newFormat)
            }
        )
    }
    private var oddsAreValid: Bool {
        guard let odds = Double(oddsText) else { return false }
        return OddsConverter.isValid(odds, format: oddsFormat)
    }
    private var riskIsValid: Bool { risk.isFinite && risk > 0 }
    private var sportsbookOptions: [String] {
        guard !sportsbook.isEmpty, !BetCatalog.sportsbooks.contains(sportsbook) else {
            return BetCatalog.sportsbooks
        }
        return [sportsbook] + BetCatalog.sportsbooks
    }
    private var decimalOdds: Double { OddsConverter.decimal(from: Double(oddsText) ?? -110, format: oddsFormat) }
    private var calculationPreview: some View {
        let validRisk = riskIsValid ? risk : 0
        return HStack {
            labelValue("RISK", validRisk.plainUnitText)
            labelValue("TO WIN", (validRisk * (decimalOdds - 1)).plainUnitText)
            labelValue("RETURN", (validRisk * decimalOdds).plainUnitText)
        }
        .padding(.vertical, 5)
    }
    private func labelValue(_ label: String, _ value: String) -> some View { VStack(alignment: .leading) { Text(label).font(.caption2).foregroundStyle(NukeTheme.cyan); Text(value).font(.headline) }.frame(maxWidth: .infinity, alignment: .leading) }
    private func quickUnit(_ value: Double) -> some View { Button("\(value, specifier: "%g")u") { risk = value }.buttonStyle(.bordered).tint(risk == value ? NukeTheme.orange : NukeTheme.muted) }

    private func hydrateForm() {
        guard !hasHydrated else { return }
        hasHydrated = true

        guard let bet = editing else {
            if let preferredFormat = profiles.first?.oddsFormat {
                oddsFormat = preferredFormat
                oddsText = preferredFormat == .american ? "-110" : "1.91"
            }
            return
        }

        title = bet.title; sport = bet.sport; league = bet.league; sportsbook = bet.sportsbook; kind = bet.kind; oddsFormat = bet.oddsFormatRaw == OddsFormat.decimal.rawValue ? .decimal : .american; oddsText = String(format: oddsFormat == .american ? "%.0f" : "%.2f", bet.oddsInput); risk = bet.riskUnits; result = bet.result; placedAt = bet.placedAt; notes = bet.notes
        legsText = (try? BetLegStore.text(for: bet.id, in: modelContext)) ?? ""
    }

    private func convertOdds(from oldFormat: OddsFormat, to newFormat: OddsFormat) {
        guard hasHydrated, oldFormat != newFormat else { return }
        guard let current = Double(oddsText), OddsConverter.isValid(current, format: oldFormat) else {
            oddsText = newFormat == .american ? "-110" : "1.91"
            return
        }

        switch newFormat {
        case .american:
            oddsText = String(format: "%.0f", OddsConverter.american(from: current))
        case .decimal:
            oddsText = String(format: "%.2f", OddsConverter.decimal(from: current, format: .american))
        }
    }

    @MainActor
    private func scanSlip(_ item: PhotosPickerItem) async {
        guard !isScanningSlip else { return }
        isScanningSlip = true
        scanFeedback = nil
        defer {
            isScanningSlip = false
            slipToScan = nil
        }

        do {
            guard let imageData = try await item.loadTransferable(type: Data.self) else {
                throw SlipRecognitionError.unreadableImage
            }

            let scan = try await SlipRecognizer.recognize(in: imageData)
            apply(scan)

            let canAttachScannedImage = existingAttachmentCount + selectedPhotos.count < 3
            if canAttachScannedImage {
                selectedPhotos.append(item)
            }
            scanFeedback = scan.summary + (canAttachScannedImage ? " The scanned image will be attached when you save." : " The photo limit is already reached.")
        } catch {
            scanFeedback = error.localizedDescription
        }
    }

    @MainActor
    private func apply(_ scan: SlipScanResult) {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let scannedTitle = scan.title {
            title = scannedTitle
        }
        if let scannedSport = scan.sport { sport = scannedSport }
        if let scannedSportsbook = scan.sportsbook { sportsbook = scannedSportsbook }
        if let scannedKind = scan.kind { kind = scannedKind }
        if let scannedOdds = scan.odds, let scannedFormat = scan.oddsFormat {
            oddsFormat = scannedFormat
            oddsText = scannedFormat == .american
                ? String(format: "%.0f", scannedOdds)
                : String(format: "%.2f", scannedOdds)
        }
        if let scannedRiskDollars = scan.riskDollars,
           let unitValue = profiles.first?.unitValue,
           unitValue.isFinite,
           unitValue > 0 {
            risk = scannedRiskDollars / unitValue
        }
    }

    @MainActor
    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        shouldDismissAfterAlert = false
        defer { isSaving = false }

        let odds = Double(oddsText) ?? -110
        let bet = editing ?? Bet(title: title, sport: sport, league: league, sportsbook: sportsbook, kind: kind, oddsInput: odds, oddsFormat: oddsFormat, riskUnits: risk, result: result, placedAt: placedAt, notes: notes)
        if editing != nil { bet.title = title; bet.sport = sport; bet.league = league; bet.sportsbook = sportsbook; bet.kindRaw = kind.rawValue; bet.oddsInput = odds; bet.oddsFormatRaw = oddsFormat.rawValue; bet.oddsDecimal = decimalOdds; bet.riskUnits = risk; bet.resultRaw = result.rawValue; bet.placedAt = placedAt; bet.settledAt = result == .pending ? nil : (bet.settledAt ?? .now); bet.notes = notes } else { modelContext.insert(bet) }
        do {
            try BetLegStore.replace(for: bet.id, with: kind == .straight ? "" : legsText, in: modelContext)
        } catch {
            modelContext.rollback()
            errorMessage = "The bet’s parlay legs could not be saved. \(error.localizedDescription)"
            return
        }

        let photoResult = await savePhotos(for: bet)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            photoResult.attachments.forEach { SlipAttachmentStore.shared.removeLocalFile(for: $0) }
            errorMessage = "Your changes could not be saved. \(error.localizedDescription)"
            return
        }

        if let photoError = photoResult.firstError {
            shouldDismissAfterAlert = true
            errorMessage = "The bet was saved, but at least one selected photo was not attached. \(photoError)"
        } else {
            dismiss()
        }
    }

    @MainActor
    private func savePhotos(for bet: Bet) async -> PhotoSaveResult {
        var firstError: String?
        var attachments: [SlipAttachment] = []
        let availableSlots = max(0, 3 - existingAttachmentCount)
        for item in selectedPhotos.prefix(availableSlots) {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                let attachment = try SlipAttachmentStore.shared.save(imageData: data, for: bet.id)
                modelContext.insert(attachment)
                attachments.append(attachment)
            } catch {
                firstError = firstError ?? error.localizedDescription
            }
        }
        return PhotoSaveResult(attachments: attachments, firstError: firstError)
    }
}

private struct PhotoSaveResult {
    let attachments: [SlipAttachment]
    let firstError: String?
}
