import SwiftUI
import SwiftData

/// A curated mirror of the selected Nuke VIP channels. Conversation remains in
/// Discord; the app does not attempt to recreate unmoderated server chat.
struct NukeVaultView: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var premiumAccess: PremiumAccessManager
    @StateObject private var feed = NukeContentFeedViewModel(visibility: .vip)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                vaultHero
                if profile.hasActiveVIPAccess {
                    verifiedVault
                } else {
                    lockedVault
                }
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(NukeCommandBackdrop())
        .navigationTitle("Nuke Vault")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            premiumAccess.configure(from: profile)
            await premiumAccess.refresh(profile: profile, in: modelContext)
            if profile.hasActiveVIPAccess {
                await feed.load(accessToken: premiumAccess.contentAccessToken)
            }
        }
        .refreshable {
            await premiumAccess.refresh(profile: profile, in: modelContext)
            if profile.hasActiveVIPAccess {
                await feed.load(accessToken: premiumAccess.contentAccessToken)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                premiumAccess.resumeAfterExternalBrowser()
            }
        }
    }

    private var vaultHero: some View {
        ZStack(alignment: .bottomLeading) {
            Image("NukeVaultHero")
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
                .opacity(0.75)
            LinearGradient(colors: [.clear, NukeTheme.abyss.opacity(0.98)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 8) {
                NukeStatusPill(
                    title: profile.hasActiveVIPAccess ? "Verified channel" : "Member channel",
                    color: profile.hasActiveVIPAccess ? NukeTheme.green : NukeTheme.ember,
                    symbol: profile.hasActiveVIPAccess ? "checkmark.shield.fill" : "lock.fill"
                )
                Text("NUKE VAULT")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .tracking(1.6)
                Text("Selected VIP picks and analyst intelligence, delivered as a clean command feed.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(NukeTheme.ember.opacity(0.38), lineWidth: 1))
    }

    private var lockedVault: some View {
        NukeCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("VERIFY YOUR MEMBERSHIP")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.2)
                    .foregroundStyle(NukeTheme.ember)
                Text("Your tracker stays free.")
                    .font(.title2.weight(.black))
                Text("Connect the Discord account that holds your Nuke VIP role to unlock the curated Vault feed. This app does not sell access outside the app or expose your private tracker data to Discord.")
                    .font(.subheadline)
                    .foregroundStyle(NukeTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                if premiumAccess.state.isWorking {
                    HStack(spacing: 9) {
                        ProgressView().tint(NukeTheme.ember)
                        Text("Opening secure Discord verification...").font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 10)
                } else {
                    Button {
                        Task {
                            if let url = await premiumAccess.beginDiscordVerification() {
                                openURL(url)
                            }
                        }
                    } label: {
                        Label("Connect Discord to verify", systemImage: "checkmark.shield.fill")
                    }
                    .buttonStyle(NukeActionButtonStyle(tint: NukeTheme.ember))
                }

                if let error = premiumAccess.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(NukeTheme.ember)
                }
            }
        }
    }

    private var verifiedVault: some View {
        VStack(spacing: 14) {
            NukeCard {
                HStack(spacing: 11) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(NukeTheme.green)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("VAULT VERIFIED").font(.caption2.weight(.heavy)).tracking(1.1).foregroundStyle(NukeTheme.green)
                        Text(profile.discordDisplayName ?? "Nuke Discord member")
                            .font(.subheadline.weight(.bold))
                    }
                    Spacer()
                    if let expiresAt = profile.premiumExpiresAt {
                        Text("Renews \(expiresAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundStyle(NukeTheme.muted)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            if let error = feed.errorMessage {
                FeedStatusNotice(message: error)
            }

            if feed.isLoading && feed.posts.isEmpty {
                ProgressView("Decrypting Vault signal...")
                    .tint(NukeTheme.ember)
                    .padding(.vertical, 36)
            } else if feed.posts.isEmpty {
                ContentUnavailableView(
                    "Vault signal is quiet",
                    systemImage: "lock.shield",
                    description: Text("Your access is verified. Check back when the next VIP briefing is published.")
                )
                .padding(.vertical, 30)
            } else {
                ForEach(feed.posts) { post in
                    EditorialPostCard(post: post)
                }
            }

            if feed.hasMore {
                Button {
                    Task { await feed.loadMore(accessToken: premiumAccess.contentAccessToken) }
                } label: {
                    Label("Load more Vault signals", systemImage: "arrow.down.circle")
                }
                .buttonStyle(NukeActionButtonStyle(tint: NukeTheme.ember))
            }
        }
    }
}

private struct FeedStatusNotice: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(NukeTheme.ember)
            Text(message).font(.caption).foregroundStyle(NukeTheme.muted)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(NukeTheme.ember.opacity(0.08), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(NukeTheme.ember.opacity(0.25), lineWidth: 0.8))
    }
}
