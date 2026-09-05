# Release Audit — Nuke Unit Tracker 1.0 (Build 4)

Audited September 4, 2026. This is an engineering and App Review readiness audit, not a promise of App Store approval or legal advice.

## Verified in this source tree

- 17 unit tests and 6 UI tests pass on the iPhone 17 Pro simulator running iOS 26.5.
- Release builds succeed for generic iOS devices with signing disabled for local verification.
- Xcode static analysis, plist linting, and Git whitespace checks pass.
- The app has no developer-operated API, analytics, advertising, tracking, login, or payment SDK.
- Bet and profile data use the user’s private CloudKit database when iCloud is available; local slip photos use iOS file protection and are not uploaded by the app.
- The persisted model schema and `NukeUnitTracker` store configuration retain legacy fields and entities from earlier builds, preventing an update from discarding existing tracker data.
- Slip scanning uses Apple Vision locally after the user explicitly chooses an image. The user reviews suggestions before saving.
- The app contains no native community feed, chat, Discord SDK, betting account connection, wager placement, live odds, deposit handling, or prize flow.

## Relevant App Review checks

| Guideline area | Source-tree status | Required outside the code |
| --- | --- | --- |
| 1.2 User-generated content | No native user-generated content. Discord is an external browser destination only. | Keep Discord content and moderation policies compliant. |
| 1.4.5 Risky behavior | The app says it does not place or transmit wagers and includes responsible-use resources. | Do not market it using guarantees, “locks,” or pressure to wager. |
| 1.5 Support | In-app Email Support opens `zodiark@nukesportsbets.com`; the public support page includes the same address. | Publish the latest support page and use the same contact in App Store Connect. |
| 2.1 Completeness | Tests, release build, error states, deletion, export, and on-device scanning are verified. | Test on the physical iPhone, record the complete flow, and publish the updated public URLs. |
| 2.3 Accurate metadata | In-app feature disclosures and the review notes are prepared. | App Store description, screenshots, age-rating answers, privacy answers, and What’s New must exactly match build 4. |
| 3.1.1 External purchase link | One optional community-membership route is clearly disclosed and release-gated to the U.S. storefront. It does not change the iOS app’s features. | Keep the app U.S.-only while this call to action ships, and show the membership page in the review recording. |
| 4.0 Design | The app is a native tracker with native logging, analytics, CSV export, local slip attachments, and local text recognition. | Use actual in-app screenshots, not title art only. |
| 5.1 Privacy | Policy, in-app link, data deletion, on-device scan disclosure, and minimized Photos access are present. | Publish the policy URL. In App Privacy, use “No, we do not collect data” only while the implementation remains as audited. |
| 5.3 Gambling | The tracker does not itself offer real-money gaming or connect to a sportsbook. | Vet the paid Whop community membership, its marketing, and availability with a qualified lawyer; Apple may scrutinize betting-adjacent paid offers. |

## Must complete before submission

1. Use `zodiark@nukesportsbets.com` as the public support contact in App Store Connect.
2. Commit and publish these files so privacy and support pages are publicly reachable on the `main` branch.
3. In CloudKit Console, deploy the finalized schema for `iCloud.com.nukesportsbets.nukeunittracker` to Production.
4. In Xcode, select the Apple Developer team, create a signing certificate if needed, archive build 4, and upload it to TestFlight.
5. Test build 4 on the physical iPhone, including iCloud sync and the slip scanner. Record the exact flow in `docs/APP_REVIEW.md`.
6. Set App Store availability to the United States only, answer the age-rating questions accurately, and update App Privacy based on the current audited build.
7. Paste the prepared Notes and Resolution Center response from `docs/APP_REVIEW.md` after replacing the physical-device placeholder.

## Do not change without re-auditing

- Adding analytics, ads, a backend, login, an AI service, live odds, or a camera changes the privacy answers and App Review notes.
- Making the community membership page visible outside the U.S. changes the external-purchase analysis.
- Making membership status unlock iOS functionality changes the payment model and is not covered by this audit.
- Changing the CloudKit model after production deployment requires a schema migration review.
- Removing or renaming a persisted model field, entity, or its `NukeUnitTracker` configuration requires a tested SwiftData migration plan before release; never reset the store to resolve a migration error.
