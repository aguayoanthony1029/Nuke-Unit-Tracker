import SwiftUI
import SwiftData

struct AppEntryView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        ZStack {
            NukeTheme.background
                .ignoresSafeArea()

            if let profile = profiles.first {
                RootTabView(profile: profile)
            } else {
                OnboardingView()
            }
        }
        .environment(\.font, NukeTheme.bodyFont())
    }
}
