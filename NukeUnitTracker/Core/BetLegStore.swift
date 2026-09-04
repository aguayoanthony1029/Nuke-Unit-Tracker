import Foundation
import SwiftData

@MainActor
enum BetLegStore {
    static func text(for betID: UUID, in modelContext: ModelContext) throws -> String {
        try fetch(for: betID, in: modelContext)
            .map(\.selection)
            .joined(separator: "\n")
    }

    static func replace(for betID: UUID, with text: String, in modelContext: ModelContext) throws {
        try fetch(for: betID, in: modelContext).forEach(modelContext.delete)

        text
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .enumerated()
            .forEach { position, selection in
                modelContext.insert(BetLeg(betID: betID, selection: selection, position: position))
            }
    }

    private static func fetch(for betID: UUID, in modelContext: ModelContext) throws -> [BetLeg] {
        let descriptor = FetchDescriptor<BetLeg>(
            predicate: #Predicate { $0.betID == betID },
            sortBy: [SortDescriptor(\BetLeg.position)]
        )
        return try modelContext.fetch(descriptor)
    }
}
