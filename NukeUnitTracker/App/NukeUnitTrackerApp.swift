import Foundation
import SwiftUI
import SwiftData
import UIKit

@main
struct NukeUnitTrackerApp: App {
    let modelContainer: ModelContainer = PersistenceController.makeContainer(
        inMemory: ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    )
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
