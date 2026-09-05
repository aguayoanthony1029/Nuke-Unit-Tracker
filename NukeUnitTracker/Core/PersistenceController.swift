import Foundation
import OSLog
import SwiftData

enum PersistenceController {
    private static let logger = Logger(subsystem: "com.nukesportsbets.nukeunittracker", category: "Persistence")

    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        // Keep this schema and configuration name stable. Changing either can
        // strand data created by an earlier version of the app.
        let schema = Schema([
            UserProfile.self,
            Bet.self,
            BetLeg.self,
            SlipAttachment.self,
            TailBoardItem.self
        ])
        let configuration = ModelConfiguration(
            "NukeUnitTracker",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : .automatic
        )

        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            guard !inMemory else {
                fatalError("Unable to initialize test storage: \(error.localizedDescription)")
            }

            logger.error("iCloud-backed storage failed to initialize; retrying local-only storage: \(error.localizedDescription, privacy: .public)")
            let localConfiguration = ModelConfiguration(
                "NukeUnitTracker",
                schema: schema,
                cloudKitDatabase: .none
            )
            do {
                return try ModelContainer(for: schema, configurations: localConfiguration)
            } catch {
                fatalError("Unable to initialize tracker storage: \(error.localizedDescription)")
            }
        }
    }
}
