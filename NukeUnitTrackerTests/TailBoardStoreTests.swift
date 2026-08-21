import XCTest
import SwiftData
@testable import NukeUnitTracker

@MainActor
final class TailBoardStoreTests: XCTestCase {
    func testPublishedSelectionIsIdempotentWithinTheSamePost() throws {
        let context = PersistenceController.makeContainer(inMemory: true).mainContext
        let pick = makePick()

        let first = TailBoardStore.save(pick, sourcePostID: "daily-board", in: context)
        let second = TailBoardStore.save(pick, sourcePostID: "daily-board", in: context)

        let items = try context.fetch(FetchDescriptor<TailBoardItem>())
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(first.id, second.id)
        XCTAssertTrue(items[0].isInBasket)
    }

    func testSameSelectionFromSeparatePostsDoesNotOverwrite() throws {
        let context = PersistenceController.makeContainer(inMemory: true).mainContext
        let pick = makePick()

        TailBoardStore.save(pick, sourcePostID: "morning-board", in: context)
        TailBoardStore.save(pick, sourcePostID: "afternoon-board", in: context)

        let items = try context.fetch(FetchDescriptor<TailBoardItem>())
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(Set(items.compactMap(\.sourcePostID)), Set(["morning-board", "afternoon-board"]))
    }

    func testClearingTheBoardPreservesSavedSelections() throws {
        let context = PersistenceController.makeContainer(inMemory: true).mainContext
        let item = TailBoardStore.save(makePick(), sourcePostID: "daily-board", in: context)

        TailBoardStore.clearBasket([item], in: context)

        let stored = try context.fetch(FetchDescriptor<TailBoardItem>())
        XCTAssertEqual(stored.count, 1)
        XCTAssertFalse(stored[0].isInBasket)
    }

    private func makePick() -> NukePick {
        NukePick(
            id: "lakers-spread",
            label: "Lakers -3.5",
            sport: "Basketball",
            league: "NBA",
            event: "Lakers at Warriors",
            selection: "Lakers -3.5",
            market: "Spread",
            line: "-3.5",
            oddsAmerican: -110,
            oddsDecimal: 1.91,
            bookmaker: "Reference only",
            startsAt: nil,
            deepLinkURL: nil
        )
    }
}
