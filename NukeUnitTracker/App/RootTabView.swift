import SwiftUI
import SwiftData

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    let profile: UserProfile
    @Query private var attachments: [SlipAttachment]
    @State private var selection: AppTab = .home
    @State private var isAddingBet = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selection {
                case .home: DashboardView(profile: profile)
                case .bets: BetsView()
                case .stats: StatsView()
                case .profile: ProfileView(profile: profile)
                }
            }
            .padding(.bottom, 74)

            NukeTabBar(selection: $selection, addAction: { isAddingBet = true })
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $isAddingBet) {
            AddBetView()
        }
        .task { await SlipAttachmentStore.shared.retryPendingUploads(attachments, in: modelContext) }
    }
}

enum AppTab: CaseIterable {
    case home, bets, stats, profile

    var title: String {
        switch self {
        case .home: "Home"
        case .bets: "Bets"
        case .stats: "Stats"
        case .profile: "You"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .bets: "list.bullet"
        case .stats: "chart.bar.xaxis"
        case .profile: "person.fill"
        }
    }
}

private struct NukeTabBar: View {
    @Binding var selection: AppTab
    let addAction: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.home)
            tabButton(.bets)
            Button(action: addAction) {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundStyle(.black)
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(NukeTheme.orange).shadow(color: NukeTheme.orange.opacity(0.5), radius: 14))
            }
            .accessibilityLabel("Add bet")
            tabButton(.stats)
            tabButton(.profile)
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) { Divider().overlay(NukeTheme.border) }
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button { selection = tab } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon).font(.system(size: 17, weight: .semibold))
                Text(tab.title).font(.caption2.weight(.semibold))
            }
            .foregroundStyle(selection == tab ? NukeTheme.orange : NukeTheme.muted)
            .frame(maxWidth: .infinity, minHeight: 46)
        }
        .accessibilityLabel(tab.title)
    }
}
