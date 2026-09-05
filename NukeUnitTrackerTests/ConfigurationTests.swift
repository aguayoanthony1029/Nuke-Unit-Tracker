import XCTest
@testable import NukeUnitTracker

final class ConfigurationTests: XCTestCase {
    func testPublicLinksUseHTTPS() {
        let links = [
            AppLinks.communityMembership,
            AppLinks.bankrollManagement,
            AppLinks.privacyPolicy,
            AppLinks.responsibleGambling
        ]

        XCTAssertTrue(links.allSatisfy { $0.scheme == "https" && $0.host != nil })
        XCTAssertEqual(AppLinks.support.scheme, "mailto")
        XCTAssertEqual(AppLinks.support.absoluteString, "mailto:zodiark@nukesportsbets.com")
    }

    func testCommunityMembershipUsesTheApprovedWhopCheckout() {
        XCTAssertEqual(AppLinks.communityMembership.host, "whop.com")
        XCTAssertTrue(AppLinks.communityMembership.path.contains("plan_0Rv2LNrHJZPKw"))
        XCTAssertEqual(AppLinks.communityMembership.query, "a=spooky47crypto")
    }

    func testWhopLinkIsLimitedToUnitedStatesStorefront() {
        XCTAssertTrue(CommunityLinkPolicy.allowsExternalLink(storefrontCountryCode: "USA"))
        XCTAssertTrue(CommunityLinkPolicy.allowsExternalLink(storefrontCountryCode: "usa"))
        XCTAssertFalse(CommunityLinkPolicy.allowsExternalLink(storefrontCountryCode: "CAN"))
        XCTAssertFalse(CommunityLinkPolicy.allowsExternalLink(storefrontCountryCode: nil))
    }
}
