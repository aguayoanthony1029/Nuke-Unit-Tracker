import SwiftData
import XCTest
@testable import NukeUnitTracker

@MainActor
final class PersistenceControllerTests: XCTestCase {
    func testInMemoryContainerStoresAllCompatibilityRecords() throws {
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
        context.insert(TailBoardItem(sourcePickID: "legacy-pick"))
        try context.save()

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<UserProfile>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Bet>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<BetLeg>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SlipAttachment>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<TailBoardItem>()), 1)
    }

    func testTrackerRecordsSurviveReopeningThePersistentStore() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "NukeUnitTrackerTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        let storeURL = directory.appending(path: "Tracker.store")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let profileID = UUID()
        let betID = UUID()

        do {
            let container = try persistentContainer(at: storeURL)
            let context = container.mainContext
            let profile = UserProfile(unitValue: 25)
            profile.id = profileID
            profile.displayName = "Existing user"
            let bet = Bet(
                title: "Existing record",
                sport: "NFL",
                league: "NFL",
                sportsbook: "",
                kind: .straight,
                oddsInput: -110,
                oddsFormat: .american,
                riskUnits: 2,
                result: .pending,
                placedAt: .now,
                notes: "Keep this"
            )
            bet.id = betID
            bet.eventIdentifier = "legacy-event"
            context.insert(profile)
            context.insert(bet)
            context.insert(BetLeg(betID: betID, selection: "Existing leg", position: 0))
            context.insert(SlipAttachment(betID: betID, localRelativePath: "existing.jpg"))
            try context.save()
        }

        let reopenedContainer = try persistentContainer(at: storeURL)
        let reopenedContext = reopenedContainer.mainContext
        let profiles = try reopenedContext.fetch(FetchDescriptor<UserProfile>())
        let bets = try reopenedContext.fetch(FetchDescriptor<Bet>())
        let legs = try reopenedContext.fetch(FetchDescriptor<BetLeg>())
        let attachments = try reopenedContext.fetch(FetchDescriptor<SlipAttachment>())

        XCTAssertEqual(profiles.count, 1)
        XCTAssertEqual(profiles.first?.id, profileID)
        XCTAssertEqual(profiles.first?.unitValue, 25)
        XCTAssertEqual(profiles.first?.displayName, "Existing user")
        XCTAssertEqual(bets.count, 1)
        XCTAssertEqual(bets.first?.id, betID)
        XCTAssertEqual(bets.first?.eventIdentifier, "legacy-event")
        XCTAssertEqual(legs.first?.selection, "Existing leg")
        XCTAssertEqual(attachments.first?.localRelativePath, "existing.jpg")
    }

    private func persistentContainer(at storeURL: URL) throws -> ModelContainer {
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
            url: storeURL,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
