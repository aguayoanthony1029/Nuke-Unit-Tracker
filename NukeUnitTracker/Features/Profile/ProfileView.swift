import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var premiumAccess: PremiumAccessManager
    @Query private var bets: [Bet]
    @Bindable var profile: UserProfile
    @State private var isConfirmingDiscordDisconnect = false

    init(profile: UserProfile) { self.profile = profile }

    var body: some View {
        NavigationStack {
            Form {
                Section("TRACKER") {
                    HStack { Text("Unit value"); Spacer(); TextField("Unit value", value: $profile.unitValue, format: .currency(code: "USD")).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                    Picker("Odds format", selection: $profile.oddsFormatRaw) { ForEach(OddsFormat.allCases) { Text($0.label).tag($0.rawValue) } }
                }
                if NukeFeatureFlags.vaultVerificationEnabled {
                    Section("NUKE VAULT") {
                        NavigationLink {
                            NukeVaultView(profile: profile)
                        } label: {
                            HStack {
                                Label("Discord membership", systemImage: profile.hasActiveVIPAccess ? "checkmark.shield.fill" : "lock.fill")
                                Spacer()
                                Text(profile.hasActiveVIPAccess ? "Verified" : "Optional")
                                    .foregroundStyle(profile.hasActiveVIPAccess ? NukeTheme.green : NukeTheme.muted)
                            }
                        }
                        Text("Your tracker stays available without a Discord account. Connect only to verify a VIP role.")
                            .font(.footnote)
                            .foregroundStyle(NukeTheme.muted)
                        if premiumAccess.hasSession {
                            Button("Disconnect Discord", role: .destructive) {
                                isConfirmingDiscordDisconnect = true
                            }
                        }
                    }
                }
                Section("DATA") {
                    LabeledContent("Tracked bets", value: "\(bets.count)")
                    Text("Your bet history is saved locally and syncs privately through iCloud when the app’s CloudKit capability is configured.").font(.footnote).foregroundStyle(NukeTheme.muted)
                }
                Section("RESPONSIBLE GAMBLING") {
                    Text("Nuke Unit Tracker is a personal tracker and community-content app. It does not accept wagers, deposits, or sportsbook credentials. Bet only what you can afford to lose.")
                    Link("Find responsible gambling resources", destination: URL(string: "https://www.ncpgambling.org/help-treatment/")!)
                }
            }
            .scrollContentBackground(.hidden).background(NukeTheme.background).navigationTitle("You")
        }
        .confirmationDialog("Disconnect Discord?", isPresented: $isConfirmingDiscordDisconnect, titleVisibility: .visible) {
            Button("Disconnect", role: .destructive) {
                Task { @MainActor in
                    await premiumAccess.disconnect(profile: profile, in: modelContext)
                }
            }
        } message: {
            Text("This removes the Nuke Vault session from this device. Your free tracker and private bet history will remain intact.")
        }
    }
}
