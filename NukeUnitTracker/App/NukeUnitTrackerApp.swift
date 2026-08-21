import SwiftUI
import SwiftData
import UIKit

@main
struct NukeUnitTrackerApp: App {
    let modelContainer: ModelContainer = PersistenceController.makeContainer()
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var premiumAccess = PremiumAccessManager()

    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .preferredColorScheme(.dark)
                .tint(NukeTheme.orange)
                .environmentObject(premiumAccess)
        }
        .modelContainer(modelContainer)
    }
}
