import SwiftData
import XCTest
@testable import NukeUnitTracker

@MainActor
final class PersistenceControllerTests: XCTestCase {
    func testInMemoryContainerStoresSyncedRecordsAndLocalAttachments() throws {
        let container = PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        let betID = UUID()

        context.insert(UserProfile(unitValue: 10))
        context.insert(Bet(
            title: "Test",
            sport: "NBA",
            league: "NBA",
            sportsbook: "",
            kind: .straight,
            oddsInput: -110,
            oddsFormat: .american,
            riskUnits: 1,
            result: .pending,
            placedAt: .now,
            notes: ""
        ))
        context.insert(BetLeg(betID: betID, selection: "Lakers -3.5", position: 0))
        context.insert(SlipAttachment(betID: betID, localRelativePath: "test.jpg"))
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<UserProfile>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Bet>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<BetLeg>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SlipAttachment>()), 1)
    }
}
