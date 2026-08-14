import Foundation
import SwiftData

enum PersistenceController {
    static func makeContainer(inMemory: Bool = false) -> ModelContainer {
        let schema = Schema([UserProfile.self, Bet.self, BetLeg.self, SlipAttachment.self])
        let configuration = ModelConfiguration(
            "NukeUnitTracker",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: inMemory ? .none : .automatic
        )
        do { return try ModelContainer(for: schema, configurations: configuration) }
        catch { fatalError("Unable to initialize private tracker storage: \(error.localizedDescription)") }
    }
}

