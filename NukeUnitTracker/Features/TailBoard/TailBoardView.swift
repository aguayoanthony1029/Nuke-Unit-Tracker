import SwiftUI
import SwiftData
import UIKit

enum TailBoardMode: String, CaseIterable, Identifiable {
    case singles
    case parlay

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var subtitle: String {
        switch self {
        case .singles: "Review each play on its own"
        case .parlay: "Combine selected legs for planning"
        }
    }
}

struct TailBoardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TailBoardItem.updatedAt, order: .reverse) private var savedItems: [TailBoardItem]
    @StateObject private var radar = TailBoardRadarViewModel()
    @State private var mode: TailBoardMode = .singles
    @State private var isShowingManualPick = false
    @State private var copied = false

    private var boardItems: [TailBoardItem] { savedItems.filter(\.isInBasket) }
    private var savedForLater: [TailBoardItem] { savedItems.filter { !$0.isInBasket } }
    private var combinedDecimalOdds: Double? {
        let odds = boardItems.compactMap(\.oddsDecimal)
        guard odds.count == boardItems.count, !odds.isEmpty else { return nil }
        return odds.reduce(1, *)
    }
    private var selectionText: String { TailBoardFormatter.text(for: boardItems, mode: mode) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                commandHeader
                modeControl

                if boardItems.isEmpty {
                    emptyBoard
                } else {
                    activeBoard
                }

                if !radar.picks.isEmpty {
                    liveRadar
                }

                if !savedForLater.isEmpty {
                    savedLibrary
                }
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(NukeCommandBackdrop())
        .navigationTitle("Tail Board")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingManualPick = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Add a manual selection")
                .tint(NukeTheme.orange)
            }
        }
        .sheet(isPresented: $isShowingManualPick) {
            ManualTailPickView()
        }
        .task { await radar.load() }
    }

    private var commandHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Image("CommandCenterHero")
                .resizable()
                .scaledToFill()
                .frame(height: 192)
                .clipped()
                .opacity(0.72)
            LinearGradient(colors: [.clear, NukeTheme.abyss.opacity(0.96)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 8) {
                NukeStatusPill(title: "Private workspace", color: NukeTheme.cyan, symbol: "lock.fill")
                Text("TAIL BOARD")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .tracking(1.8)
                Text("Save Nuke signals or add your own. Copy the final list only when you are ready to review it yourself.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(NukeTheme.cyan.opacity(0.32), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private var modeControl: some View {
        NukeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("BUILD MODE").font(.caption2.weight(.heavy)).tracking(1.2).foregroundStyle(NukeTheme.muted)
                        Text(mode.subtitle).font(.subheadline.weight(.semibold))
                    }
                    Spacer()
                    NukeStatusPill(title: "\(boardItems.count) queued", color: boardItems.isEmpty ? NukeTheme.muted : NukeTheme.green)
                }
                HStack(spacing: 8) {
                    ForEach(TailBoardMode.allCases) { choice in
                        Button {
                            mode = choice
                            copied = false
                        } label: {
                            Text(choice.title)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(mode == choice ? .black : NukeTheme.muted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(mode == choice ? NukeTheme.orange : NukeTheme.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(mode == choice ? NukeTheme.orange : NukeTheme.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(mode == choice ? .isSelected : [])
                    }
                }
            }
        }
    }

    private var emptyBoard: some View {
        NukeCard {
            VStack(spacing: 14) {
                Image(systemName: "scope")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(NukeTheme.cyan)
                    .frame(width: 62, height: 62)
                    .background(NukeTheme.cyan.opacity(0.13), in: Circle())
                Text("Your board is clear")
                    .font(.title3.weight(.black))
                Text("Build a private board from your own notes. You can save it, copy it, or share it when you are ready.")
                    .font(.subheadline)
                    .foregroundStyle(NukeTheme.muted)
                    .multilineTextAlignment(.center)
                Button {
                    isShowingManualPick = true
                } label: {
                    Label("ADD A SELECTION", systemImage: "plus")
                }
                .buttonStyle(NukeActionButtonStyle(tint: NukeTheme.orange))
                .accessibilityLabel("Add a manual selection")
            }
            .padding(.vertical, 10)
        }
    }

    private var activeBoard: some View {
        VStack(alignment: .leading, spacing: 10) {
            NukeSectionHeader(
                eyebrow: "Your selections",
                title: mode == .parlay ? "Parlay staging area" : "Single-play staging area",
                actionTitle: "Clear board",
                action: {
                    TailBoardStore.clearBasket(boardItems, in: modelContext)
                    copied = false
                }
            )
            NukeCard {
                VStack(spacing: 0) {
                    ForEach(boardItems) { item in
                        TailBoardItemRow(item: item, isOnBoard: true) {
                            TailBoardStore.setBasketState(item, isInBasket: false, in: modelContext)
                            copied = false
                        } remove: {
                            TailBoardStore.remove(item, from: modelContext)
                            copied = false
                        }
                        if item.id != boardItems.last?.id {
                            Divider().overlay(NukeTheme.border.opacity(0.72))
                        }
                    }
                }
            }

            if mode == .parlay {
                parlayEstimate
            }

            VStack(spacing: 10) {
                Button {
                    UIPasteboard.general.string = selectionText
                    copied = true
                } label: {
                    Label(copied ? "Selections copied" : "Copy selections", systemImage: copied ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(NukeActionButtonStyle(tint: copied ? NukeTheme.green : NukeTheme.orange))

                ShareLink(item: selectionText) {
                    Label("Share selection list", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(NukeTheme.cyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(NukeTheme.cyan.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(NukeTheme.cyan.opacity(0.4), lineWidth: 1))
                }
            }

            Text("Nuke Unit Tracker does not open sportsbooks, load wagers, or place bets. Lines and odds can move - always review details independently.")
                .font(.caption2)
                .foregroundStyle(NukeTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    private var parlayEstimate: some View {
        NukeCard {
            HStack(spacing: 14) {
                Image(systemName: "function")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(NukeTheme.ember)
                VStack(alignment: .leading, spacing: 3) {
                    Text("ESTIMATED COMBINED ODDS").font(.caption2.weight(.heavy)).tracking(1.0).foregroundStyle(NukeTheme.muted)
                    if let combinedDecimalOdds {
                        Text("\(String(format: "%.2f", combinedDecimalOdds)) decimal  /  \(String(format: "%+.0f", OddsConverter.american(from: combinedDecimalOdds)))")
                            .font(.headline.weight(.black))
                            .foregroundStyle(NukeTheme.ember)
                    } else {
                        Text("Awaiting odds for every leg")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(NukeTheme.muted)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var liveRadar: some View {
        VStack(alignment: .leading, spacing: 10) {
            NukeSectionHeader(eyebrow: "Live feed", title: "Nuke radar")
            NukeCard {
                VStack(spacing: 0) {
                    ForEach(radar.picks) { pick in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .foregroundStyle(NukeTheme.cyan)
                                .frame(width: 22)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(pick.label).font(.subheadline.weight(.bold))
                                Text([pick.event, pick.marketLine, pick.displayOdds].filter { !$0.isEmpty }.joined(separator: "  |  "))
                                    .font(.caption)
                                    .foregroundStyle(NukeTheme.muted)
                                    .lineLimit(2)
                            }
                            Spacer(minLength: 4)
                            TailBoardAddButton(pick: pick)
                        }
                        .padding(.vertical, 9)
                        if pick.id != radar.picks.last?.id { Divider().overlay(NukeTheme.border.opacity(0.72)) }
                    }
                }
            }
        }
    }

    private var savedLibrary: some View {
        VStack(alignment: .leading, spacing: 10) {
            NukeSectionHeader(eyebrow: "Saved for later", title: "Private stash")
            NukeCard {
                VStack(spacing: 0) {
                    ForEach(savedForLater) { item in
                        TailBoardItemRow(item: item, isOnBoard: false) {
                            TailBoardStore.setBasketState(item, isInBasket: true, in: modelContext)
                            copied = false
                        } remove: {
                            TailBoardStore.remove(item, from: modelContext)
                        }
                        if item.id != savedForLater.last?.id {
                            Divider().overlay(NukeTheme.border.opacity(0.72))
                        }
                    }
                }
            }
        }
    }
}

struct TailBoardAddButton: View {
    @Environment(\.modelContext) private var modelContext
    let pick: NukePick
    var sourcePostID: String? = nil
    @State private var isAdded = false

    var body: some View {
        Button {
            TailBoardStore.save(pick, sourcePostID: sourcePostID, in: modelContext)
            isAdded = true
        } label: {
            Label(isAdded ? "On board" : "Add", systemImage: isAdded ? "checkmark" : "plus")
                .font(.caption.weight(.heavy))
                .foregroundStyle(isAdded ? NukeTheme.green : NukeTheme.orange)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background((isAdded ? NukeTheme.green : NukeTheme.orange).opacity(0.14), in: Capsule())
                .overlay(Capsule().stroke((isAdded ? NukeTheme.green : NukeTheme.orange).opacity(0.48), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isAdded ? "Selection is on Tail Board" : "Add \(pick.label) to Tail Board")
    }
}

private struct TailBoardItemRow: View {
    let item: TailBoardItem
    let isOnBoard: Bool
    let toggleBasket: () -> Void
    let remove: () -> Void
    @State private var isShowingRemoveConfirmation = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isOnBoard ? "checkmark.circle.fill" : "bookmark.fill")
                .foregroundStyle(isOnBoard ? NukeTheme.green : NukeTheme.cyan)
                .font(.title3)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.label).font(.subheadline.weight(.bold)).lineLimit(2)
                Text([item.event, item.cleanSelectionLine, item.displayOdds].filter { !$0.isEmpty }.joined(separator: "  |  "))
                    .font(.caption)
                    .foregroundStyle(NukeTheme.muted)
                    .lineLimit(2)
                if let startsAt = item.startsAt {
                    Text(startsAt, format: .dateTime.weekday(.abbreviated).hour().minute())
                        .font(.caption2)
                        .foregroundStyle(NukeTheme.cyan)
                }
            }
            Spacer(minLength: 2)
            Menu {
                Button(isOnBoard ? "Save for later" : "Add to board", action: toggleBasket)
                Button("Remove saved selection", role: .destructive) { isShowingRemoveConfirmation = true }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(NukeTheme.muted)
                    .frame(width: 30, height: 30)
            }
        }
        .padding(.vertical, 9)
        .confirmationDialog("Remove this saved selection?", isPresented: $isShowingRemoveConfirmation, titleVisibility: .visible) {
            Button("Remove", role: .destructive, action: remove)
        }
    }
}

private struct ManualTailPickView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var event = ""
    @State private var selection = ""
    @State private var market = ""
    @State private var line = ""
    @State private var sport = "NBA"
    @State private var league = ""
    @State private var bookmaker = ""
    @State private var americanOdds = ""
    @State private var includeStartTime = false
    @State private var startsAt = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("SELECTION") {
                    TextField("Game or event", text: $event)
                    TextField("Your selection", text: $selection)
                    TextField("Market (optional)", text: $market)
                    TextField("Line (optional)", text: $line)
                }
                Section("CONTEXT") {
                    Picker("Sport", selection: $sport) {
                        ForEach(["NBA", "NFL", "MLB", "NHL", "NCAAF", "NCAAB", "Soccer", "Other"], id: \.self) { Text($0) }
                    }
                    TextField("League (optional)", text: $league)
                    TextField("Sportsbook reference (optional)", text: $bookmaker)
                    TextField("American odds (optional)", text: $americanOdds)
                        .keyboardType(.numbersAndPunctuation)
                    Toggle("Add a start time", isOn: $includeStartTime)
                    if includeStartTime {
                        DatePicker("Start", selection: $startsAt)
                    }
                }
                Section {
                    Text("A manual Tail Board entry is a private note. It does not log a bet or connect to any sportsbook.")
                        .font(.footnote)
                        .foregroundStyle(NukeTheme.muted)
                }
            }
            .scrollContentBackground(.hidden)
            .background(NukeTheme.background)
            .navigationTitle("Add selection")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(event.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let title = [event, selection].filter { !$0.isEmpty }.joined(separator: " - ")
        let pick = TailBoardStore.makeManualPick(
            title: title,
            sport: sport,
            league: league,
            event: event,
            selection: selection,
            market: market,
            line: line,
            americanOdds: Double(americanOdds),
            bookmaker: bookmaker,
            startsAt: includeStartTime ? startsAt : nil
        )
        TailBoardStore.save(pick, addToBasket: true, in: modelContext)
        dismiss()
    }
}

private enum TailBoardFormatter {
    static func text(for items: [TailBoardItem], mode: TailBoardMode) -> String {
        let heading = mode == .singles ? "Singles" : "Parlay planning"
        var lines = ["NUKE TAIL BOARD", heading, ""]
        for (index, item) in items.enumerated() {
            let details = [item.event, item.cleanSelectionLine, item.displayOdds]
                .filter { !$0.isEmpty }
                .joined(separator: " | ")
            lines.append("\(index + 1). \(item.label)")
            if !details.isEmpty { lines.append("   \(details)") }
        }
        if mode == .parlay {
            let odds = items.compactMap(\.oddsDecimal)
            if odds.count == items.count, !odds.isEmpty {
                let decimal = odds.reduce(1, *)
                lines += ["", "Estimated combined odds: \(String(format: "%.2f", decimal)) decimal / \(String(format: "%+.0f", OddsConverter.american(from: decimal))) American"]
            }
        }
        lines += ["", "Review current lines and odds independently before making any decision."]
        return lines.joined(separator: "\n")
    }
}
