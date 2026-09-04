# Nuke Unit Tracker

Nuke Unit Tracker is a free iPhone app for adults to manually record sports-betting activity in units and review personal results. It does not accept money, connect to sportsbook accounts, provide live odds, place or transmit wagers, or award prizes.

The optional Community page opens one external page for Nuke Sports Bets community membership. Membership does not unlock anything in the iOS app.

## Run the iPhone app

Requirements:

- A Mac with the current stable Xcode release
- XcodeGen (`brew install xcodegen`), or the included launcher script

From Terminal:

```bash
cd ~/Developer/Nuke-Unit-Tracker
bash Scripts/open-ios.sh
```

Then in Xcode:

1. Select the `NukeUnitTracker` scheme.
2. Choose an iPhone simulator and press Run.
3. For a physical iPhone, choose the app target under Signing & Capabilities, enable automatic signing, select your Apple Developer team, unlock and trust the iPhone, and choose it as the run destination.

`project.yml` is the source of truth. `NukeUnitTracker.xcodeproj` is generated locally and intentionally ignored by Git.

No API keys, Discord bot, database, or backend service are required.

## What the release includes

- Manual bet logging with American or decimal odds
- On-device slip scanning that prefills recognizable details for review
- Straight, parlay, and same-game parlay records
- Win, loss, push, void, and pending states
- Unit, ROI, calendar, sport, sportsbook, and bet-type statistics
- Search, filters, bet editing, settlement, deletion, and CSV export
- Up to three device-local slip photos per bet
- Private iCloud sync for tracker records when iCloud is available
- Privacy, support, responsible-use, and full-data-deletion controls
- A U.S.-storefront-only external link to optional community membership

## Tests

Generate the project, then run:

```bash
xcodebuild \
  -project NukeUnitTracker.xcodeproj \
  -scheme NukeUnitTracker \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.5' \
  test \
  CODE_SIGNING_ALLOWED=NO
```

Choose any installed iPhone simulator if that exact simulator is unavailable.

## App Store release

Before submitting a new build:

1. Test the complete flow on a physical iPhone through TestFlight and record it from app launch.
2. Confirm iCloud and CloudKit are enabled for `com.nukesportsbets.nukeunittracker`, then deploy the finalized CloudKit schema to Production in CloudKit Console before TestFlight or App Store upload.
3. Use U.S.-only App Store availability for this version while the external Whop action is present.
4. Set the age rating override to 18+ and answer gambling-content questions accurately.
5. Publish the [privacy policy](docs/PRIVACY.md) and use its public HTTPS address in App Store Connect.
6. Paste the prepared information from [App Review Submission Guide](docs/APP_REVIEW.md) into App Review Information and the Resolution Center reply.
7. Use screenshots of the app’s working tracker, history, and stats screens—not only launch or onboarding art.

## Privacy

Tracker records are stored locally and may sync through the user’s private iCloud database. Slip photos and optional slip-text recognition remain on the device. The app has no advertising, analytics, tracking SDK, AI service, or developer-operated server. See [docs/PRIVACY.md](docs/PRIVACY.md).
