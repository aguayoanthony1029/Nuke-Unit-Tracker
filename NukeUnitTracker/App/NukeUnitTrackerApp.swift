import Foundation
import SwiftUI
import SwiftData

@main
struct NukeUnitTrackerApp: App {
    let modelContainer: ModelContainer = PersistenceController.makeContainer(
        inMemory: ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || ProcessInfo.processInfo.arguments.contains("--ui-testing")
    )

    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .preferredColorScheme(.dark)
                .tint(NukeTheme.orange)
        }
        .modelContainer(modelContainer)
    }
}
