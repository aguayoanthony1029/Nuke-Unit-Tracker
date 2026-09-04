# Release Audit — Nuke Unit Tracker 1.0 (Build 3)

Audited September 4, 2026. This is an engineering and App Review readiness audit, not a promise of App Store approval or legal advice.

## Verified in this source tree

- 15 unit tests and 6 UI tests pass on the iPhone 17 Pro simulator running iOS 26.5.
- Release builds succeed for generic iOS devices with signing disabled for local verification.
- Xcode static analysis, plist linting, and Git whitespace checks pass.
- The app has no developer-operated API, analytics, advertising, tracking, login, or payment SDK.
- Bet and profile data use the user’s private CloudKit database when iCloud is available; local slip photos use iOS file protection and are not uploaded by the app.
- Slip scanning uses Apple Vision locally after the user explicitly chooses an image. The user reviews suggestions before saving.
- The app contains no native community feed, chat, Discord SDK, betting account connection, wager placement, live odds, deposit handling, or prize flow.

## Relevant App Review checks

| Guideline area | Source-tree status | Required outside the code |
| --- | --- | --- |
| 1.2 User-generated content | No native user-generated content. Discord is an external browser destination only. | Keep Discord content and moderation policies compliant. |
| 1.4.5 Risky behavior | The app says it does not place or transmit wagers and includes responsible-use resources. | Do not market it using guarantees, “locks,” or pressure to wager. |
| 1.5 Support | In-app Support is reachable. | Add a real public support email; GitHub Issues should not be the only contact route. |
| 2.1 Completeness | Tests, release build, error states, deletion, export, and on-device scanning are verified. | Test on the physical iPhone, record the complete flow, and publish the updated public URLs. |
| 2.3 Accurate metadata | In-app feature disclosures and the review notes are prepared. | App Store description, screenshots, age-rating answers, privacy answers, and What’s New must exactly match build 3. |
| 3.1.1 External purchase link | One optional community-membership route is clearly disclosed and release-gated to the U.S. storefront. It does not change the iOS app’s features. | Keep the app U.S.-only while this call to action ships, and show the membership page in the review recording. |
| 4.0 Design | The app is a native tracker with native logging, analytics, CSV export, local slip attachments, and local text recognition. | Use actual in-app screenshots, not title art only. |
| 5.1 Privacy | Policy, in-app link, data deletion, on-device scan disclosure, and minimized Photos access are present. | Publish the policy URL. In App Privacy, use “No, we do not collect data” only while the implementation remains as audited. |
| 5.3 Gambling | The tracker does not itself offer real-money gaming or connect to a sportsbook. | Vet the paid Whop community membership, its marketing, and availability with a qualified lawyer; Apple may scrutinize betting-adjacent paid offers. |

## Must complete before submission

1. Add the public support email to `docs/SUPPORT.md`, `docs/PRIVACY.md`, and App Store Connect.
2. Commit and publish these files so privacy and support pages are publicly reachable on the `main` branch.
3. In CloudKit Console, deploy the finalized schema for `iCloud.com.nukesportsbets.nukeunittracker` to Production.
4. In Xcode, select the Apple Developer team, create a signing certificate if needed, archive build 3, and upload it to TestFlight.
5. Test build 3 on the physical iPhone, including iCloud sync and the slip scanner. Record the exact flow in `docs/APP_REVIEW.md`.
6. Set App Store availability to the United States only, answer the age-rating questions accurately, and update App Privacy based on the current audited build.
7. Paste the prepared Notes and Resolution Center response from `docs/APP_REVIEW.md` after replacing the physical-device placeholder.

## Do not change without re-auditing

- Adding analytics, ads, a backend, login, an AI service, live odds, or a camera changes the privacy answers and App Review notes.
- Making the community membership page visible outside the U.S. changes the external-purchase analysis.
- Making membership status unlock iOS functionality changes the payment model and is not covered by this audit.
- Changing the CloudKit model after production deployment requires a schema migration review.
