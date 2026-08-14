import SwiftUI
import SwiftData

struct AppEntryView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if let profile = profiles.first {
                RootTabView(profile: profile)
            } else {
                OnboardingView()
            }
        }
        .background(NukeTheme.background)
    }
}

