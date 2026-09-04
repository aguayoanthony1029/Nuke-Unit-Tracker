import Foundation
import SwiftData
import XCTest
@testable import NukeUnitTracker

@MainActor
final class BetLegStoreTests: XCTestCase {
    func testRoundTripsAndReplacesParlayLegsInOrder() throws {
        let schema = Schema([BetLeg.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: configuration)
        let context = container.mainContext
        let betID = UUID()

        try BetLegStore.replace(
            for: betID,
            with: "  Lakers -3.5  \n\nOver 224.5\n Anthony Davis 8+ rebounds ",
            in: context
        )

        XCTAssertEqual(
            try BetLegStore.text(for: betID, in: context),
            "Lakers -3.5\nOver 224.5\nAnthony Davis 8+ rebounds"
        )

        try BetLegStore.replace(for: betID, with: "Suns moneyline", in: context)
        XCTAssertEqual(try BetLegStore.text(for: betID, in: context), "Suns moneyline")
    }
}
