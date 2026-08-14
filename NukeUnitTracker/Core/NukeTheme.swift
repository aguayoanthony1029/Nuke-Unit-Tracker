import SwiftUI

enum NukeTheme {
    static let background = Color(red: 0.015, green: 0.02, blue: 0.03)
    static let surface = Color(red: 0.055, green: 0.07, blue: 0.10)
    static let surfaceRaised = Color(red: 0.075, green: 0.095, blue: 0.135)
    static let border = Color(red: 0.18, green: 0.22, blue: 0.30)
    static let orange = Color(red: 1.0, green: 0.40, blue: 0.02)
    static let cyan = Color(red: 0.0, green: 0.67, blue: 0.98)
    static let green = Color(red: 0.16, green: 0.90, blue: 0.48)
    static let red = Color(red: 1.0, green: 0.29, blue: 0.32)
    static let muted = Color(red: 0.52, green: 0.60, blue: 0.70)
}

struct NukeCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding()
            .background(NukeTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(NukeTheme.border, lineWidth: 1))
    }
}

extension Double {
    var unitText: String { String(format: "%@%.2fu", self >= 0 ? "+" : "", self) }
    var plainUnitText: String { String(format: "%.2fu", self) }
    var dollarText: String { "$" + String(format: "%.2f", self) }
}

