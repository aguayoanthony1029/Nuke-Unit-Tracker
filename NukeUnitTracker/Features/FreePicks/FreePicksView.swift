import SwiftUI

struct FreePicksPreview: View {
    let openFeed: () -> Void
    var body: some View {
        Button(action: openFeed) {
            ZStack(alignment: .bottomLeading) {
                Image("Banner").resizable().scaledToFill().frame(height: 145).clipped().opacity(0.72)
                LinearGradient(colors: [.clear, .black.opacity(0.95)], startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 4) { Text("NUKE FREE PICKS").font(.headline.bold()); Text("See the latest picks from Nuke Sports Bets →").font(.caption).foregroundStyle(.white.opacity(0.8)) }.padding()
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(NukeTheme.border))
        }
        .buttonStyle(.plain)
    }
}

struct FreePicksView: View {
    @StateObject private var viewModel = FreePicksViewModel()
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Image("Banner").resizable().scaledToFill().frame(height: 185).clipped().clipShape(RoundedRectangle(cornerRadius: 18))
                if viewModel.picks.isEmpty && !viewModel.isLoading { ContentUnavailableView("No free picks yet", systemImage: "bolt.fill", description: Text("Check back when Nuke posts the next play.")) }
                ForEach(viewModel.picks) { pick in FreePickCard(pick: pick) }
            }.padding()
        }
        .background(NukeTheme.background)
        .navigationTitle("Free Picks")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }
}

private struct FreePickCard: View {
    let pick: FreePick
    var body: some View {
        NukeCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(pick.postedAt, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundStyle(NukeTheme.cyan)
                Text(pick.content).font(.body)
                ForEach(pick.imageURLs, id: \.self) { url in AsyncImage(url: url) { image in image.resizable().scaledToFit() } placeholder: { ProgressView().frame(maxWidth: .infinity, minHeight: 120) } }
                if let url = pick.discordURL { Link("Open in Discord", destination: url).font(.subheadline.bold()).foregroundStyle(NukeTheme.orange) }
            }
        }
    }
}

