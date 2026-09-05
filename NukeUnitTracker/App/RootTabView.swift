import SwiftUI
import SwiftData

struct RootTabView: View {
    let profile: UserProfile
    @State private var selection: AppTab = .home
    @State private var isAddingBet = false

    var body: some View {
        // The root owns the viewport, background, and safe-area reservation.
        // Individual tabs only own their scrollable content.
        ZStack {
            NukeTheme.background
                .ignoresSafeArea()

            NukeCommandBackdrop()

            selectedScreen
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            NukeTabBar(selection: $selection, addAction: { isAddingBet = true })
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $isAddingBet) {
            AddBetView()
        }
    }

    @ViewBuilder
    private var selectedScreen: some View {
        switch selection {
        case .home: DashboardView(profile: profile)
        case .bets: BetsView()
        case .stats: StatsView()
        case .profile: ProfileView(profile: profile)
        }
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
                ZStack {
                    Circle()
                        .fill(NukeTheme.bgBase)

                    Circle()
                        .stroke(NukeTheme.neonOrange, lineWidth: 2)
                        .neonGlow(color: NukeTheme.neonOrange)

                    VStack(spacing: 1) {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .shadow(color: NukeTheme.neonOrange.opacity(0.75), radius: 3)
                        Text("LOG")
                            .font(NukeTheme.headerFont(size: 10, relativeTo: .caption2))
                            .tracking(0.9)
                    }
                    .foregroundStyle(NukeTheme.neonOrange)
                }
                .frame(width: 64, height: 64)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Log a bet")
            tabButton(.stats)
            tabButton(.profile)
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(NukeTheme.bgBase.opacity(0.82))
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 12, y: 4)
        .accessibilityIdentifier("main-tab-bar")
    }

    private func tabButton(_ tab: AppTab) -> some View {
        Button { selection = tab } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon).font(.system(size: 17, weight: .semibold))
                Text(tab.title.uppercased())
                    .font(NukeTheme.headerFont(size: 10, relativeTo: .caption2))
                    .tracking(0.5)
            }
            .foregroundStyle(selection == tab ? NukeTheme.neonOrange : Color.white.opacity(0.46))
            .frame(maxWidth: .infinity, minHeight: 46)
        }
        .accessibilityLabel(tab.title)
    }
}
