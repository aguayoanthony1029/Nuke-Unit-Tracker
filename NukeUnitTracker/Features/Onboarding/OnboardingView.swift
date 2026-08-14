import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var unitValue = 10.0

    var body: some View {
        VStack(spacing: 26) {
            Spacer()
            Image("BrandMark")
                .resizable().scaledToFit().frame(width: 130, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            VStack(spacing: 8) {
                Text("Nuke Unit Tracker").font(.largeTitle.bold())
                Text("Track your sports bets in seconds.").foregroundStyle(NukeTheme.muted)
            }
            NukeCard {
                VStack(alignment: .leading, spacing: 18) {
                    Text("A couple quick details").font(.headline)
                    TextField("Display name", text: $name).textInputAutocapitalization(.words).textFieldStyle(.roundedBorder)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("One unit is worth").font(.caption).foregroundStyle(NukeTheme.muted)
                        TextField("$10", value: $unitValue, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    }
                    Text("You can change this later. Your bet history stays private to your device and iCloud account.")
                        .font(.caption).foregroundStyle(NukeTheme.muted)
                }
            }
            Button("Start Tracking") { modelContext.insert(UserProfile(displayName: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Nuke Member" : name, unitValue: max(unitValue, 0.01))) }
                .buttonStyle(NukePrimaryButton())
            Spacer()
        }
        .padding(24)
        .background(NukeTheme.background.ignoresSafeArea())
    }
}

struct NukePrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.headline).foregroundStyle(.black).frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(NukeTheme.orange.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 15))
    }
}

