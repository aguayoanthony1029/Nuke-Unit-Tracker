import SwiftUI
import SwiftData

struct AppEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var premiumAccess: PremiumAccessManager
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first {
                RootTabView(profile: profile)
            } else {
                OnboardingView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NukeTheme.background, ignoresSafeAreaEdges: .all)
        .onOpenURL { url in
            guard let profile = profiles.first else { return }
            Task { @MainActor in
                await premiumAccess.handleCallback(url: url, profile: profile, in: modelContext)
            }
        }
    }
}
