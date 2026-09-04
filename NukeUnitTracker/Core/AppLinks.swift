import Foundation

enum AppLinks {
    static let communityMembership = URL(string: "https://whop.com/checkout/plan_0Rv2LNrHJZPKw?a=spooky47crypto")!
    static let bankrollManagement = URL(string: "https://www.youtube.com/watch?v=y13Tknx33v0")!
    static let privacyPolicy = URL(string: "https://github.com/aguayoanthony1029/Nuke-Unit-Tracker/blob/main/docs/PRIVACY.md")!
    static let support = URL(string: "https://github.com/aguayoanthony1029/Nuke-Unit-Tracker/issues")!
    static let responsibleGambling = URL(string: "https://www.ncpgambling.org/help-treatment/")!
}

enum CommunityLinkPolicy {
    static func allowsExternalLink(storefrontCountryCode: String?) -> Bool {
        storefrontCountryCode?.uppercased() == "USA"
    }
}
