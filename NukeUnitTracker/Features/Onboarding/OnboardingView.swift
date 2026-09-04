import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var unitValue = 10.0
    @State private var saveError: String?

    var body: some View {
        ZStack {
            NukeCommandBackdrop()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    brandHeader
                    missionPanel
                    setupPanel
                    VStack(spacing: 5) {
                        Text("For adults 18+. Personal tracking and educational use only.")
                        Text("Private by default. Your tracker works without an account and stays yours.")
                    }
                    .font(.footnote)
                    .foregroundStyle(NukeTheme.muted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 122)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(action: createProfile) {
                Label("START TRACKING", systemImage: "bolt.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(NukePrimaryButton())
            .disabled(!unitValueIsValid)
            .opacity(unitValueIsValid ? 1 : 0.55)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background(.ultraThinMaterial)
        }
        .alert("Couldn’t Start Tracker", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveError ?? "")
        }
    }

    private var brandHeader: some View {
        HStack(alignment: .center, spacing: 16) {
            Image("BrandMark")
                .resizable()
                .scaledToFit()
                .frame(width: 76, height: 76)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(NukeTheme.orange.opacity(0.55), lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                Text("NUKE")
                    .font(.system(size: 31, weight: .black, design: .rounded))
                    .tracking(2)
                Text("UNIT TRACKER")
                    .font(.caption.weight(.heavy))
                    .tracking(2.2)
                    .foregroundStyle(NukeTheme.orange)
                Text("YOUR PRIVATE WAR ROOM")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(NukeTheme.cyan)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
    }

    private var missionPanel: some View {
        NukeCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "scope")
                    .font(.title2.weight(.black))
                    .foregroundStyle(NukeTheme.cyan)
                    .frame(width: 36, height: 36)
                    .background(NukeTheme.cyan.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 6) {
                    Text("SET UP YOUR TRACKER")
                        .font(.headline.weight(.black))
                    Text("Log action fast. Review your units. Keep the story in the numbers.")
                        .font(.subheadline)
                        .foregroundStyle(NukeTheme.muted)
                }
            }
        }
    }

    private var setupPanel: some View {
        NukeCard {
            VStack(alignment: .leading, spacing: 18) {
                Text("INITIALIZE YOUR TRACKER")
                    .font(.caption.weight(.heavy))
                    .tracking(1.3)
                    .foregroundStyle(NukeTheme.orange)

                VStack(alignment: .leading, spacing: 7) {
                    Text("ONE UNIT IS WORTH")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(NukeTheme.muted)
                    TextField("$10", value: $unitValue, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(NukeFieldStyle())
                    if !unitValueIsValid {
                        Text("Enter a unit value greater than zero.")
                            .font(.caption)
                            .foregroundStyle(NukeTheme.red)
                    }
                }

                HStack(spacing: 8) {
                    Label("No account", systemImage: "lock.fill")
                    Label("Change anytime", systemImage: "slider.horizontal.3")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(NukeTheme.cyan)
            }
        }
    }

    private var unitValueIsValid: Bool { unitValue.isFinite && unitValue > 0 }

    private func createProfile() {
        guard unitValueIsValid else {
            saveError = "Enter a unit value greater than zero."
            return
        }
        modelContext.insert(UserProfile(unitValue: unitValue))
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            saveError = error.localizedDescription
        }
    }
}

struct NukePrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.black))
            .tracking(0.8)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(NukeTheme.orange.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .shadow(color: NukeTheme.orange.opacity(configuration.isPressed ? 0 : 0.34), radius: 14, y: 6)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct NukeFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(NukeTheme.abyss.opacity(0.74), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(NukeTheme.border, lineWidth: 1))
    }
}
