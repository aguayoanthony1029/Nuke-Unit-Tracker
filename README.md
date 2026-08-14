# Nuke Unit Tracker

Nuke Unit Tracker is an iOS 17+ SwiftUI app for recording sports bets in units, reviewing performance, and viewing Nuke Sports Bets free picks. It is a tracker and community-content companion; it never accepts wagers or deposits.

## Open in Xcode

1. Clone this repository on a Mac running the current Xcode release.
2. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).
3. From the repository root, run `xcodegen generate`.
4. Open `NukeUnitTracker.xcodeproj`, select an Apple Developer team, and update `NukeUnitTracker/Config/Secrets.xcconfig` from the included example.
5. Enable iCloud/CloudKit and Push Notifications for the selected bundle identifier before testing cloud sync or notifications.

The generated Xcode project is intentionally ignored: `project.yml` is the source of truth, so project settings remain reviewable in Git.

## Configuration

Copy `NukeUnitTracker/Config/Secrets.example.xcconfig` to `Secrets.xcconfig`. Do not commit it. The mobile app only needs public service URLs and the optional Odds API key. Discord tokens and APNs credentials belong only in `community-service/.env`.

## Community service

The `community-service` directory contains the Node/TypeScript Discord relay and public Free Picks API. It mirrors posts from one trusted Discord role in one configured channel, persists them in Postgres, and sends opt-in APNs notifications.

```powershell
cd community-service
Copy-Item .env.example .env
npm install
npm run migrate
npm run dev
```

Create a Discord bot, enable the Message Content intent, invite it to the Nuke server, and set `DISCORD_GUILD_ID`, `DISCORD_FREE_PICKS_CHANNEL_ID`, and `DISCORD_TRUSTED_ROLE_ID`. Use Render for the web service and managed Postgres; `render.yaml` provides the deployment outline.

## Release checklist

- Create the App ID, iCloud container, and APNs key in the Apple Developer portal.
- Test local persistence, iCloud sync, image upload retry, export, and migration on physical devices. Add the `SlipAsset` record type to the private CloudKit schema before testing photo sync.
- Configure production database, Discord bot, APNs credentials, API URL, privacy policy, support URL, and notification copy.
- Promote the CloudKit schema only after testing it in development.
- Run the Swift unit/UI tests and community-service tests; then distribute through TestFlight.

## Privacy

Personal bets and slip images remain in the user’s local/iCloud private store. The community service receives only its public device notification token/preferences and public Discord free-pick content. See [docs/PRIVACY.md](docs/PRIVACY.md).
