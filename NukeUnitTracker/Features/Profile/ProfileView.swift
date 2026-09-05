import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var bets: [Bet]
    @Query private var legs: [BetLeg]
    @Query private var attachments: [SlipAttachment]
    @Bindable var profile: UserProfile
    @State private var isEditingUnitValue = false
    @State private var isConfirmingDataDeletion = false
    @State private var dataDeletionError: String?
    @State private var unitValueSaveError: String?

    init(profile: UserProfile) { self.profile = profile }

    var body: some View {
        NavigationStack {
            Form {
                Section("TRACKER") {
                    Button {
                        isEditingUnitValue = true
                    } label: {
                        HStack {
                            Text("Unit value")
                            Spacer()
                            Text(profile.unitValue, format: .currency(code: "USD"))
                                .foregroundStyle(.primary)
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(NukeTheme.muted)
                        }
                    }
                    .accessibilityIdentifier("edit-unit-value-button")

                    Picker("Odds format", selection: $profile.oddsFormatRaw) {
                        ForEach(OddsFormat.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                    Text("Unit value must be greater than zero. You can change it at any time.")
                        .font(.footnote)
                        .foregroundStyle(NukeTheme.muted)
                }

                Section("YOUR DATA") {
                    LabeledContent("Tracked bets", value: "\(bets.count)")
                    LabeledContent("Slip photos", value: "\(attachments.count)")
                    LabeledContent("Photo storage", value: SlipAttachmentStore.shared.storageUsageDescription)
                    Text("Tracker records sync through your private iCloud database when iCloud is available. Slip photos stay only on this device and are capped at \(SlipAttachmentStore.shared.storageLimitDescription).")
                        .font(.footnote)
                        .foregroundStyle(NukeTheme.muted)

                    Button("Delete all app data", role: .destructive) {
                        isConfirmingDataDeletion = true
                    }
                    .accessibilityIdentifier("delete-all-data-button")
                }

                Section("PRIVACY & SUPPORT") {
                    Link(destination: AppLinks.privacyPolicy) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    .accessibilityIdentifier("privacy-policy-link")
                    Link(destination: AppLinks.support) {
                        Label("Email Support", systemImage: "questionmark.circle.fill")
                    }
                    .accessibilityIdentifier("support-link")
                }

                Section("RESPONSIBLE USE") {
                    Text("Nuke Unit Tracker is a personal record-keeping tool. It does not accept deposits, connect to sportsbook accounts, place or transmit wagers, or award prizes. Bet only what you can afford to lose.")
                    Link(destination: AppLinks.responsibleGambling) {
                        Label("Responsible gambling resources", systemImage: "lifepreserver.fill")
                    }
                    .accessibilityIdentifier("responsible-use-link")
                }

                Section("ABOUT") {
                    LabeledContent("Version", value: versionText)
                    Text("Optional community membership is separate from the app and does not unlock tracker features.")
                        .font(.footnote)
                        .foregroundStyle(NukeTheme.muted)
                }
            }
            .scrollContentBackground(.hidden)
            .background(NukeTheme.background)
            .navigationTitle("You")
        }
        .sheet(isPresented: $isEditingUnitValue) {
            UnitValueEditor(
                initialValue: profile.unitValue,
                onSave: saveUnitValue
            )
        }
        .confirmationDialog("Delete all app data?", isPresented: $isConfirmingDataDeletion, titleVisibility: .visible) {
            Button("Delete Everything", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes your profile, tracked bets, parlay legs, and slip photos from this device. Synced tracker records will also be removed from your private iCloud database.")
        }
        .alert("Couldn’t delete all data", isPresented: Binding(
            get: { dataDeletionError != nil },
            set: { if !$0 { dataDeletionError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(dataDeletionError ?? "")
        }
        .alert("Couldn’t save unit value", isPresented: Binding(
            get: { unitValueSaveError != nil },
            set: { if !$0 { unitValueSaveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(unitValueSaveError ?? "")
        }
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
    }

    private func deleteAllData() {
        let attachmentPaths = attachments.map(\.localRelativePath)
        attachments.forEach {
            modelContext.delete($0)
        }
        legs.forEach(modelContext.delete)
        bets.forEach(modelContext.delete)
        profiles.forEach(modelContext.delete)

        do {
            try modelContext.save()
            attachmentPaths.forEach { SlipAttachmentStore.shared.removeLocalFile(relativePath: $0) }
        } catch {
            modelContext.rollback()
            dataDeletionError = error.localizedDescription
        }
    }

    private func saveUnitValue(_ newValue: Double) -> Bool {
        guard newValue.isFinite, newValue > 0 else { return false }

        let previousValue = profile.unitValue
        profile.unitValue = newValue

        do {
            try modelContext.save()
            return true
        } catch {
            profile.unitValue = previousValue
            modelContext.rollback()
            unitValueSaveError = error.localizedDescription
            return false
        }
    }
}

private struct UnitValueEditor: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isUnitFieldFocused: Bool

    let onSave: (Double) -> Bool

    @State private var draftValue: String
    @State private var isShowingValidationError = false

    init(initialValue: Double, onSave: @escaping (Double) -> Bool) {
        self.onSave = onSave
        _draftValue = State(initialValue: Self.displayValue(for: initialValue))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("UNIT VALUE") {
                    HStack(spacing: 4) {
                        Text("$")
                            .font(.title3.weight(.semibold))
                        TextField("10.00", text: $draftValue)
                            .focused($isUnitFieldFocused)
                            .keyboardType(.decimalPad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityIdentifier("unit-value-input")
                    }
                    .font(.title3)

                    Text("Use the dollar amount that one unit represents. Your existing records stay in units; only their dollar equivalent updates.")
                        .font(.footnote)
                        .foregroundStyle(NukeTheme.muted)
                }

                if isShowingValidationError {
                    Section {
                        Text("Enter a unit value greater than zero.")
                            .foregroundStyle(NukeTheme.red)
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Change unit value")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .accessibilityIdentifier("save-unit-value-button")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isUnitFieldFocused = false }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear { isUnitFieldFocused = true }
    }

    private var parsedValue: Double? {
        let trimmed = draftValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Self.numberFormatter.number(from: trimmed)?.doubleValue,
              value.isFinite,
              value > 0 else { return nil }
        return value
    }

    private func save() {
        guard let value = parsedValue else {
            isShowingValidationError = true
            return
        }

        guard onSave(value) else { return }
        dismiss()
    }

    private static func displayValue(for value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current
        formatter.isLenient = false
        return formatter
    }()
}
