import Foundation
import SwiftData

enum TailBoardStore {
    /// Adds a published selection to a user's private board. Source IDs make
    /// repeated taps idempotent, while still allowing publishers to update the
    /// selection details on a later refresh.
    @discardableResult
    static func save(
        _ pick: NukePick,
        sourcePostID: String? = nil,
        addToBasket: Bool = true,
        in modelContext: ModelContext
    ) -> TailBoardItem {
        // Editorial pick IDs are useful labels, not guaranteed globally unique
        // (e.g. a recurring "Lakers spread" card). Scope them to the post when
        // the API provides that context so saved boards never overwrite each
        // other across separate Nuke drops.
        let sourceID = [sourcePostID ?? pick.contentID, pick.id]
            .compactMap { $0 }
            .joined(separator: ":")
        let descriptor = FetchDescriptor<TailBoardItem>(predicate: #Predicate { item in
            item.sourcePickID == sourceID
        })

        if let existing = try? modelContext.fetch(descriptor).first {
            apply(pick, sourcePostID: sourcePostID, to: existing)
            existing.isInBasket = addToBasket || existing.isInBasket
            existing.updatedAt = .now
            try? modelContext.save()
            return existing
        }

        let item = TailBoardItem(
            pick: pick,
            sourcePostID: sourcePostID,
            sourcePickID: sourceID,
            isInBasket: addToBasket
        )
        modelContext.insert(item)
        try? modelContext.save()
        return item
    }

    static func setBasketState(_ item: TailBoardItem, isInBasket: Bool, in modelContext: ModelContext) {
        item.isInBasket = isInBasket
        item.updatedAt = .now
        try? modelContext.save()
    }

    static func remove(_ item: TailBoardItem, from modelContext: ModelContext) {
        modelContext.delete(item)
        try? modelContext.save()
    }

    static func clearBasket(_ items: [TailBoardItem], in modelContext: ModelContext) {
        for item in items where item.isInBasket {
            item.isInBasket = false
            item.updatedAt = .now
        }
        try? modelContext.save()
    }

    static func makeManualPick(
        title: String,
        sport: String,
        league: String,
        event: String,
        selection: String,
        market: String,
        line: String,
        americanOdds: Double?,
        bookmaker: String,
        startsAt: Date?
    ) -> NukePick {
        NukePick(
            id: "manual-\(UUID().uuidString)",
            label: title,
            sport: sport,
            league: league.nilIfBlank,
            event: event,
            selection: selection,
            market: market.nilIfBlank,
            line: line.nilIfBlank,
            oddsAmerican: americanOdds,
            oddsDecimal: americanOdds.map { OddsConverter.decimal(from: $0, format: .american) },
            bookmaker: bookmaker.nilIfBlank,
            startsAt: startsAt,
            deepLinkURL: nil
        )
    }

    private static func apply(_ pick: NukePick, sourcePostID: String?, to item: TailBoardItem) {
        item.sourcePostID = sourcePostID ?? pick.contentID ?? item.sourcePostID
        item.label = pick.label
        item.sport = pick.sport
        item.league = pick.league
        item.event = pick.event
        item.selection = pick.selection
        item.market = pick.market
        item.line = pick.line
        item.oddsAmerican = pick.oddsAmerican
        item.oddsDecimal = pick.normalizedDecimalOdds
        item.bookmaker = pick.bookmaker
        item.startsAt = pick.startsAt
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
