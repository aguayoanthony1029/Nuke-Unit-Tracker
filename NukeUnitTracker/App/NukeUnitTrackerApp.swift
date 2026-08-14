import SwiftUI
import SwiftData

@main
struct NukeUnitTrackerApp: App {
    let modelContainer: ModelContainer = PersistenceController.makeContainer()
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .preferredColorScheme(.dark)
                .tint(NukeTheme.orange)
        }
        .modelContainer(modelContainer)
    }
}
