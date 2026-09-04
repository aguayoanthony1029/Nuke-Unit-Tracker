import Foundation
import OSLog
import SwiftData

enum PersistenceController {
    private static let logger = Logger(subsystem: "com.nukesportsbets.nukeunittracker", category: "Persistence")

    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let syncedSchema = Schema([
            UserProfile.self,
            Bet.self,
            BetLeg.self
        ])
        let attachmentSchema = Schema([SlipAttachment.self])
        let fullSchema = Schema([
            UserProfile.self,
            Bet.self,
            BetLeg.self,
            SlipAttachment.self
        ])
        let syncedConfiguration = ModelConfiguration(
            "NukeUnitTracker",
            schema: syncedSchema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : .automatic
        )
        let attachmentConfiguration = ModelConfiguration(
            "NukeUnitTrackerAttachments",
            schema: attachmentSchema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )

        do {
            return try ModelContainer(
                for: fullSchema,
                configurations: syncedConfiguration, attachmentConfiguration
            )
        } catch {
            guard !inMemory else {
                fatalError("Unable to initialize test storage: \(error.localizedDescription)")
            }

            logger.error("iCloud-backed storage failed to initialize; retrying local-only storage: \(error.localizedDescription, privacy: .public)")
            let localConfiguration = ModelConfiguration(
                "NukeUnitTracker",
                schema: syncedSchema,
                cloudKitDatabase: .none
            )
            do {
                return try ModelContainer(
                    for: fullSchema,
                    configurations: localConfiguration, attachmentConfiguration
                )
            } catch {
                fatalError("Unable to initialize tracker storage: \(error.localizedDescription)")
            }
        }
    }
}
