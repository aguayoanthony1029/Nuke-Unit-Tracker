import SwiftUI

struct NukeCommunityInvite: View {
    let openCommunity: () -> Void

    var body: some View {
        Button(action: openCommunity) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    NukeStatusPill(title: "Community access", color: NukeTheme.cyan, symbol: "person.3.fill")
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(NukeTheme.orange)
                }
                Text("JOIN THE NUKE SPORTS BETS COMMUNITY FOR EXPERT PICKS!")
                    .font(.headline.weight(.black))
                    .tracking(0.5)
                Text("Expert picks, AI-powered tools, and a community built for the board.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background { previewBackdrop }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(NukeTheme.cyan.opacity(0.3)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Join the Nuke Sports Bets Community")
    }

    private var previewBackdrop: some View {
        GeometryReader { proxy in
            ZStack {
                Image("CommandCenterHero")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                    .opacity(0.68)
                LinearGradient(colors: [.clear, NukeTheme.abyss.opacity(0.96)], startPoint: .top, endPoint: .bottom)
            }
        }
    }
}

struct NukeCommunityView: View {
    @Environment(\.dismiss) private var dismiss

    private let membershipURL = URL(string: "https://whop.com/checkout/plan_0Rv2LNrHJZPKw?a=spooky47crypto")!

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                communityHero

                NukeCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Want access to expert picks and a community of like-minded sports bettors?  Join the Nuke Sports Bets community today!  Get access to a dozen expert handicappers, automated AI-powered betting tools, and an active community of sports enthusiasts. Sign up on Whop and connect your Discord account to join the server.")
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Elevate your sports betting experience today.")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(NukeTheme.cyan)

                        Link(destination: membershipURL) {
                            Label("CLICK HERE", systemImage: "bolt.shield.fill")
                                .font(.subheadline.weight(.heavy))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(NukeTheme.orange, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                                .shadow(color: NukeTheme.orange.opacity(0.28), radius: 12, y: 5)
                        }
                        .accessibilityHint("Opens the Nuke Sports Bets membership page in your browser")

                        Text("Opens the membership page in your browser.")
                            .font(.caption2)
                            .foregroundStyle(NukeTheme.muted)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .background(NukeCommandBackdrop())
        .navigationTitle("Nuke Community")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Close community invitation")
            }
        }
    }

    private var communityHero: some View {
        ZStack(alignment: .bottomLeading) {
            Image("CommandCenterHero")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .aspectRatio(1.75, contentMode: .fit)
                .clipped()
                .opacity(0.78)
            LinearGradient(colors: [.clear, NukeTheme.abyss.opacity(0.98)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 8) {
                NukeStatusPill(title: "Nuke Sports Bets", color: NukeTheme.orange, symbol: "bolt.fill")
                Text("JOIN NUKE SPORTS BETS")
                    .font(.title2.weight(.black))
                    .tracking(1.05)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Access expert picks & analysis")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(NukeTheme.orange.opacity(0.45), lineWidth: 1))
    }
}

struct FreePicksView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NukeContentFeedViewModel(visibility: .free)

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                feedHeader

                if viewModel.isShowingLocalBriefing {
                    LocalBriefingNotice()
                }

                if let errorMessage = viewModel.errorMessage {
                    FeedNotice(message: errorMessage, color: NukeTheme.ember, symbol: "exclamationmark.triangle.fill")
                }

                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView("Scanning the Nuke signal...")
                        .tint(NukeTheme.cyan)
                        .padding(.vertical, 48)
                } else if viewModel.posts.isEmpty {
                    ContentUnavailableView(
                        "No free signals yet",
                        systemImage: "antenna.radiowaves.left.and.right",
                        description: Text("The tracker is ready. Check back when Nuke posts the next briefing.")
                    )
                    .padding(.vertical, 36)
                } else {
                    ForEach(viewModel.posts) { post in
                        EditorialPostCard(post: post)
                    }
                }

                if viewModel.hasMore {
                    Button {
                        Task { await viewModel.loadMore() }
                    } label: {
                        if viewModel.isLoadingMore {
                            ProgressView().frame(maxWidth: .infinity).padding(.vertical, 12)
                        } else {
                            Label("Load more signals", systemImage: "arrow.down.circle")
                        }
                    }
                    .buttonStyle(NukeActionButtonStyle(tint: NukeTheme.cyan))
                }
            }
            .padding()
            .padding(.bottom, 24)
        }
        .background(NukeCommandBackdrop())
        .navigationTitle("Free Picks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Close free picks")
            }
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    TailBoardView()
                } label: {
                    Image(systemName: "scope")
                }
                .accessibilityLabel("Open Tail Board")
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private var feedHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Image("CommandCenterHero")
                .resizable()
                .scaledToFill()
                .frame(height: 212)
                .clipped()
                .opacity(0.78)
            LinearGradient(colors: [.clear, NukeTheme.abyss.opacity(0.98)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 7) {
                NukeStatusPill(title: "Open to everyone", color: NukeTheme.green, symbol: "checkmark.shield.fill")
                Text("THE FREE ZONE")
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .tracking(1.4)
                Text("Fresh Nuke briefings, free picks, and field intelligence. No account required.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(NukeTheme.cyan.opacity(0.34), lineWidth: 1))
    }
}

struct EditorialPostCard: View {
    let post: NukeEditorialPost
    @State private var isExpanded = false

    var body: some View {
        NukeCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: post.kind.symbol)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(kindColor)
                        .frame(width: 32, height: 32)
                        .background(kindColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(post.kind.label.uppercased())
                            .font(.caption2.weight(.heavy))
                            .tracking(1)
                            .foregroundStyle(kindColor)
                        Text(post.publishedAt, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                            .font(.caption2)
                            .foregroundStyle(NukeTheme.muted)
                    }
                    Spacer()
                    if post.visibility == .vip {
                        NukeStatusPill(title: "Vault", color: NukeTheme.ember, symbol: "lock.fill")
                    }
                }

                Text(post.title)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                if !post.summary.isEmpty {
                    Text(post.summary)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.84))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let heroURL = post.heroImageURL {
                    RemoteContentImage(url: heroURL, height: 178)
                }

                if !post.body.isEmpty, post.body != post.summary {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { isExpanded.toggle() }
                    } label: {
                        HStack {
                            Text(isExpanded ? "Hide field note" : "Read field note")
                            Spacer()
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(NukeTheme.cyan)
                    }
                    .buttonStyle(.plain)

                    if isExpanded {
                        Text(post.body)
                            .font(.subheadline)
                            .foregroundStyle(NukeTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                if !post.imageURLs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(post.imageURLs, id: \.self) { url in
                                RemoteContentImage(url: url, height: 128)
                                    .frame(width: 190)
                            }
                        }
                    }
                }

                if !post.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(post.tags, id: \.self) { tag in
                                NukeStatusPill(title: tag, color: NukeTheme.muted)
                            }
                        }
                    }
                }

                if let sourceURL = post.sourceURL {
                    Link(destination: sourceURL) {
                        HStack(spacing: 7) {
                            Image(systemName: sourceLabel(for: sourceURL).symbol)
                            Text(sourceLabel(for: sourceURL).title)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(NukeTheme.cyan)
                        .padding(.vertical, 4)
                    }
                    .accessibilityLabel("\(sourceLabel(for: sourceURL).title) in browser")
                }

                if !post.picks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("TAILABLE SELECTIONS")
                                .font(.caption2.weight(.heavy))
                                .tracking(1)
                                .foregroundStyle(NukeTheme.orange)
                            Spacer()
                            Text("Review independently")
                                .font(.caption2)
                                .foregroundStyle(NukeTheme.muted)
                        }
                        ForEach(post.picks) { pick in
                            EditorialPickRow(pick: pick, postID: post.id)
                        }
                    }
                    .padding(11)
                    .background(NukeTheme.background.opacity(0.55), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(NukeTheme.orange.opacity(0.24), lineWidth: 0.8))
                }
            }
        }
    }

    private var kindColor: Color {
        switch post.kind {
        case .brief: NukeTheme.cyan
        case .analysis: NukeTheme.green
        case .news: NukeTheme.ember
        case .pickCard: NukeTheme.orange
        case .announcement: NukeTheme.red
        case .other: NukeTheme.muted
        }
    }

    private func sourceLabel(for url: URL) -> (title: String, symbol: String) {
        if url.host?.localizedCaseInsensitiveContains("discord") == true {
            return ("Open discussion in Discord", "bubble.left.and.bubble.right.fill")
        }
        return ("Open source", "arrow.up.right.square")
    }
}

private struct EditorialPickRow: View {
    let pick: NukePick
    let postID: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: "scope")
                .foregroundStyle(NukeTheme.orange)
                .frame(width: 20, height: 20)
            VStack(alignment: .leading, spacing: 3) {
                Text(pick.label)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(2)
                Text([pick.event, pick.marketLine, pick.displayOdds].filter { !$0.isEmpty }.joined(separator: "  |  "))
                    .font(.caption)
                    .foregroundStyle(NukeTheme.muted)
                    .lineLimit(2)
                if let startsAt = pick.startsAt {
                    Text(startsAt, format: .dateTime.weekday(.abbreviated).hour().minute())
                        .font(.caption2)
                        .foregroundStyle(NukeTheme.cyan)
                }
            }
            Spacer(minLength: 3)
            TailBoardAddButton(pick: pick, sourcePostID: postID)
        }
        .padding(.vertical, 4)
    }
}

private struct RemoteContentImage: View {
    let url: URL
    let height: CGFloat

    var body: some View {
        AsyncImage(url: url, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                Color.black.opacity(0.25).overlay(Image(systemName: "photo").foregroundStyle(NukeTheme.muted))
            default:
                Color.black.opacity(0.25).overlay(ProgressView().tint(NukeTheme.cyan))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

private struct LocalBriefingNotice: View {
    var body: some View {
        FeedNotice(
            message: "The Nuke content signal is not connected yet, so you are seeing the offline Field Manual. Your bet tracker and Tail Board still work normally.",
            color: NukeTheme.cyan,
            symbol: "antenna.radiowaves.left.and.right"
        )
    }
}

private struct FeedNotice: View {
    let message: String
    let color: Color
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: symbol).foregroundStyle(color)
            Text(message).font(.caption).foregroundStyle(NukeTheme.muted)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(color.opacity(0.25), lineWidth: 0.8))
    }
}
