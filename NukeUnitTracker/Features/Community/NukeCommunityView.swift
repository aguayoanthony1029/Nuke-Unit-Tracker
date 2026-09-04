import StoreKit
import SwiftUI

struct NukeCommunityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var storefrontCountryCode: String?
    @State private var isCheckingStorefront = true

    private var canOpenCommunityMembership: Bool {
#if DEBUG
        true
#else
        CommunityLinkPolicy.allowsExternalLink(storefrontCountryCode: storefrontCountryCode)
#endif
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                communityHero
                communitySection
                educationSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(NukeCommandBackdrop())
        .navigationTitle("Nuke Community")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Close community invitation")
            }
        }
        .task {
            storefrontCountryCode = await Storefront.current?.countryCode
            isCheckingStorefront = false
            for await storefront in Storefront.updates {
                storefrontCountryCode = storefront.countryCode
            }
        }
    }

    private var communitySection: some View {
        NukeCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Connect with the Nuke Sports Bets community outside the app.")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)

                Label("Membership is separate from the tracker", systemImage: "rectangle.on.rectangle.slash")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(NukeTheme.cyan)

                Text("Nuke Unit Tracker is free to use. An optional membership does not unlock content or features in this app.")
                    .font(.subheadline)
                    .foregroundStyle(NukeTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("community-separation-disclosure")

                if canOpenCommunityMembership {
                    Link(destination: AppLinks.communityMembership) {
                        Label("VIEW COMMUNITY MEMBERSHIP", systemImage: "arrow.up.right")
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(NukeTheme.orange, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                            .shadow(color: NukeTheme.orange.opacity(0.28), radius: 12, y: 5)
                    }
                    .accessibilityHint("Opens the optional Nuke Sports Bets community membership page in your browser")
                    .accessibilityIdentifier("community-membership-link")

                    Text("Opens in your browser. Current membership price and terms are shown before purchase. For adults 18 and older.")
                        .font(.caption2)
                        .foregroundStyle(NukeTheme.muted)
                } else if isCheckingStorefront {
                    ProgressView("Checking availability…")
                        .tint(NukeTheme.orange)
                        .font(.caption)
                } else {
                    Text("Community membership is currently available only in the United States App Store storefront.")
                        .font(.caption)
                        .foregroundStyle(NukeTheme.muted)
                }
            }
        }
    }

    private var educationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            NukeSectionHeader(eyebrow: "Nuke Academy", title: "Learn the fundamentals")

            NukeCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("BANKROLL MANAGEMENT")
                        .font(NukeTheme.headerFont(size: 17, relativeTo: .headline))
                        .tracking(0.9)
                        .foregroundStyle(NukeTheme.hudCyan)

                    Text("Learn how unit sizing can help you set limits and review results consistently.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)

                    Link(destination: AppLinks.bankrollManagement) {
                        Label("WATCH ON YOUTUBE", systemImage: "play.rectangle.fill")
                            .font(NukeTheme.headerFont(size: 14, relativeTo: .subheadline))
                            .tracking(0.8)
                            .foregroundStyle(NukeTheme.hudCyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(NukeTheme.hudCyan.opacity(0.11), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(NukeTheme.hudCyan.opacity(0.48), lineWidth: 1)
                            )
                    }
                    .accessibilityHint("Opens the bankroll management video on YouTube")

                    Text("Educational content only. The app does not recommend or place wagers.")
                        .font(.caption2)
                        .foregroundStyle(NukeTheme.muted)
                }
            }
        }
    }

    private var communityHero: some View {
        ZStack(alignment: .bottomLeading) {
            Image("CommandCenterHero")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(1.75, contentMode: .fit)
                .clipped()
                .opacity(0.78)
            LinearGradient(colors: [.clear, NukeTheme.abyss.opacity(0.98)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 8) {
                NukeStatusPill(title: "Community membership", color: NukeTheme.orange, symbol: "person.3.fill")
                Text("JOIN THE CONVERSATION")
                    .font(.title2.weight(.black))
                    .tracking(1.05)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Come join the Nuke Sports Bets Discord community.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(NukeTheme.orange.opacity(0.45), lineWidth: 1))
    }
}
