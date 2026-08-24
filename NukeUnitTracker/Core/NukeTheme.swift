import SwiftUI

enum NukeTheme {
    // MARK: - Visual Lab palette

    /// #0B0E14 - the deepest command-center background.
    static let bgBase = Color(
        red: 11.0 / 255.0,
        green: 14.0 / 255.0,
        blue: 20.0 / 255.0
    )

    /// #181D26 - raised panels and tactical surfaces.
    static let bgSurface = Color(
        red: 24.0 / 255.0,
        green: 29.0 / 255.0,
        blue: 38.0 / 255.0
    )

    /// #FF6B00 - primary actions and hot HUD accents.
    static let neonOrange = Color(
        red: 1.0,
        green: 107.0 / 255.0,
        blue: 0.0
    )

    /// #22C55E - positive performance and confirmed states.
    static let matrixGreen = Color(
        red: 34.0 / 255.0,
        green: 197.0 / 255.0,
        blue: 94.0 / 255.0
    )

    /// #EF4444 - losses, destructive actions, and alerts.
    static let alertRed = Color(
        red: 239.0 / 255.0,
        green: 68.0 / 255.0,
        blue: 68.0 / 255.0
    )

    /// #00E5FF - telemetry, charts, and active HUD signals.
    static let hudCyan = Color(
        red: 0.0,
        green: 229.0 / 255.0,
        blue: 1.0
    )

    // Existing tokens remain unchanged during the theme-foundation step.
    // Screens will migrate to the Visual Lab palette deliberately in later passes.
    static let background = Color(red: 0.015, green: 0.02, blue: 0.03)
    static let abyss = Color(red: 0.008, green: 0.012, blue: 0.02)
    static let surface = Color(red: 0.055, green: 0.07, blue: 0.10)
    static let surfaceRaised = Color(red: 0.075, green: 0.095, blue: 0.135)
    static let border = Color(red: 0.18, green: 0.22, blue: 0.30)
    static let orange = Color(red: 1.0, green: 0.40, blue: 0.02)
    static let ember = Color(red: 1.0, green: 0.60, blue: 0.03)
    static let cyan = Color(red: 0.0, green: 0.67, blue: 0.98)
    static let cyanDim = Color(red: 0.0, green: 0.37, blue: 0.56)
    static let green = Color(red: 0.16, green: 0.90, blue: 0.48)
    static let red = Color(red: 1.0, green: 0.29, blue: 0.32)
    static let muted = Color(red: 0.52, green: 0.60, blue: 0.70)

    static let commandGradient = LinearGradient(
        colors: [abyss, background, Color(red: 0.025, green: 0.055, blue: 0.085)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct TacticalCardStyle: ViewModifier {
    private let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)

    func body(content: Content) -> some View {
        content
            .background(NukeTheme.bgSurface, in: shape)
            .overlay {
                shape
                    .stroke(Color.white.opacity(0.10), lineWidth: 1)
            }
            .overlay {
                // A clipped, softened dark stroke creates an inset edge without
                // changing the content's size or hit-testing behavior.
                shape
                    .stroke(Color.black.opacity(0.62), lineWidth: 4)
                    .blur(radius: 3)
                    .offset(y: 2)
                    .clipShape(shape)
                    .allowsHitTesting(false)
            }
            .clipShape(shape)
    }
}

struct NeonGlow: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.88), radius: 3)
            .shadow(color: color.opacity(0.42), radius: 14)
    }
}

extension View {
    func tacticalCard() -> some View {
        modifier(TacticalCardStyle())
    }

    func neonGlow(color: Color) -> some View {
        modifier(NeonGlow(color: color))
    }
}

struct NukeCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding()
            .background(
                LinearGradient(
                    colors: [NukeTheme.surfaceRaised, NukeTheme.surface.opacity(0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [NukeTheme.cyan.opacity(0.25), NukeTheme.border, NukeTheme.ember.opacity(0.18)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.24), radius: 10, y: 5)
    }
}

/// A subtle, GPU-cheap command-center field used behind dashboards and feeds.
/// It deliberately avoids heavy animations so quick logging remains fast.
struct NukeCommandBackdrop: View {
    var body: some View {
        ZStack {
            NukeTheme.commandGradient
            RadialGradient(
                colors: [NukeTheme.cyan.opacity(0.10), .clear],
                center: .topTrailing,
                startRadius: 12,
                endRadius: 420
            )
            RadialGradient(
                colors: [NukeTheme.orange.opacity(0.10), .clear],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 360
            )
            Canvas { context, size in
                var grid = Path()
                let spacing: CGFloat = 42
                for x in stride(from: CGFloat.zero, through: size.width, by: spacing) {
                    grid.move(to: CGPoint(x: x, y: 0))
                    grid.addLine(to: CGPoint(x: x, y: size.height))
                }
                for y in stride(from: CGFloat.zero, through: size.height, by: spacing) {
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(grid, with: .color(NukeTheme.cyan.opacity(0.035)), lineWidth: 0.5)
            }
        }
        .accessibilityHidden(true)
    }
}

struct NukeSectionHeader: View {
    let eyebrow: String
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    init(
        eyebrow: String,
        title: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(eyebrow.uppercased())
                    .font(.caption2.weight(.heavy))
                    .tracking(1.4)
                    .foregroundStyle(NukeTheme.orange)
                Text(title)
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
            }
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(NukeTheme.cyan)
            }
        }
    }
}

struct NukeStatusPill: View {
    let title: String
    var color: Color = NukeTheme.cyan
    var symbol: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let symbol { Image(systemName: symbol) }
            Text(title.uppercased())
        }
        .font(.caption2.weight(.heavy))
        .tracking(0.8)
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.13), in: Capsule())
        .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 0.75))
    }
}

struct NukeActionButtonStyle: ButtonStyle {
    var tint: Color = NukeTheme.orange

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.heavy))
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(tint.opacity(configuration.isPressed ? 0.78 : 1), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .shadow(color: tint.opacity(configuration.isPressed ? 0 : 0.28), radius: 12, y: 5)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

extension Double {
    var unitText: String { String(format: "%@%.2fu", self >= 0 ? "+" : "", self) }
    var plainUnitText: String { String(format: "%.2fu", self) }
    var dollarText: String { "$" + String(format: "%.2f", self) }
}
