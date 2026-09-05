# App Review Submission Guide

This guide is for build 4 of Nuke Unit Tracker 1.0. Complete the physical-device test and replace any bracketed item before copying the notes into App Store Connect.

## Before resubmitting

1. Merge or publish these changes so the updated privacy and support documents are publicly reachable from the repository’s `main` branch.
2. In CloudKit Console, select `iCloud.com.nukesportsbets.nukeunittracker` and deploy the finalized development schema to Production. TestFlight and App Store builds can use only the production environment.
3. Upload build 4 to TestFlight and install it on the physical iPhone.
4. Delete the old app first so the recording begins at onboarding.
5. Complete the recording script below without a crash, blank screen, or unfinished feature.
6. Add the recording to the Resolution Center reply.
7. Set availability to the United States only while the Whop action is part of this release.
8. Set the age rating override to 18+ and answer the gambling-related content questions accurately.
9. Use `https://github.com/aguayoanthony1029/Nuke-Unit-Tracker/blob/main/docs/PRIVACY.md` for the Privacy Policy URL and `https://github.com/aguayoanthony1029/Nuke-Unit-Tracker/blob/main/docs/SUPPORT.md` for the Support URL.
10. In App Privacy, declare **No, we do not collect data from this app** only if this build remains unchanged: records use the user’s private CloudKit database (not visible to the developer), and slip recognition stays on device with no analytics, login, or developer server.
11. Confirm that `zodiark@nukesportsbets.com` is shown as the public support contact in App Store Connect. GitHub Issues remain an additional option.

## Physical-device recording script

Record the whole screen and begin before tapping the app icon. A two-to-three-minute recording is enough.

1. Launch Nuke Unit Tracker and show onboarding.
2. Leave the unit value at $10 and tap **Start Tracking**.
3. Tap **Log**, choose **Scan a slip to prefill**, select an ordinary slip image or screenshot, show the locally prefilled suggestions, review/correct them, then enter `App Review Demo - Lakers vs Suns` if needed. Keep American odds at `-110`, set risk to `1u`, and save.
4. Open **Bets**, open the demo record, and settle it as a win.
5. Return to **Home** to show the updated unit total and chart.
6. Open **Stats** and show the record, ROI, calendar, and category charts.
7. Open **Bets**, tap **Export**, show the iOS share sheet, then dismiss it without sending anything.
8. Open **You** and show the data summary, Privacy Policy, Support, responsible-use text, version, and **Delete all app data** control. You may open the delete confirmation and cancel it.
9. Return to **Home**, open **Join the Community**, and show the disclosure that community membership is separate from the app. Tap **View Community Membership**, show Whop’s current price and renewal terms without entering any information, then return to the app.

No app account, demo credentials, sample file, location permission, camera permission, contact permission, microphone permission, notification permission, or App Tracking Transparency prompt is required. The optional community-membership purchase happens externally in the browser and is not required to access any app feature. The optional system Photos picker can use any ordinary image if Review wants to test a slip attachment or on-device text recognition; no broad Photos-library permission is requested.

## Paste into App Review Information → Notes

NUKE UNIT TRACKER 1.0 (BUILD 4) — REVIEW INFORMATION

1. PHYSICAL-DEVICE RECORDING
A screen recording is attached to our Resolution Center reply. It starts with app launch and shows onboarding, manual bet entry, history, settlement, dashboard/stat updates, CSV export, settings/privacy controls, full-data deletion confirmation, and the optional external community-membership handoff.

2. TEST DEVICES
- iPhone 16 Pro Max — iOS 27.0 beta 8 (24A5430a), physical device via TestFlight. [KEEP ONLY AFTER COMPLETING THE TEST ABOVE]
- iPhone 17 Pro Simulator — iOS 26.5, automated unit and UI tests.

3. FUNCTIONS, AUDIENCE, AND VALUE
Nuke Unit Tracker is a free personal record-keeping and analytics utility for adults 18 and older who want to log sports-betting activity in consistent units and review their own results. Users manually enter records or scan a selected slip to prefill visible details, settle outcomes, search/filter history, view unit/ROI/calendar/category statistics, attach device-local slip photos, and export CSV data. Slip scanning is on device; users review suggestions before saving. The app does not accept money, place or transmit wagers, connect to sportsbook accounts, award prizes, or provide live odds.

4. ACCESS INSTRUCTIONS
No login or demo credentials are required. Launch the app, choose a unit value, and tap Start Tracking. Use the center Log button to add a record. Choose **Scan slip** in the top-right corner to select one or more images; the app processes text on device and suggests details for review. Use Bets to open, edit, settle, filter, delete, or export records; Stats for analytics; and You for preferences, privacy/support links, and full-data deletion. No sample file is required. Any image may be selected for attachment or scan testing.

5. EXTERNAL SERVICES
- Apple SwiftData and the user’s private iCloud/CloudKit database for tracker-record storage and sync.
- Apple Photos picker for user-selected, device-local slip images.
- Apple Vision to scan text locally in selected slip images; no image or recognized text leaves the device.
- Whop for an optional browser-based Nuke Sports Bets community membership. Whop handles account creation, payment, renewal, cancellation, and any referral or discount eligibility.
- Discord hosts that separate community; no Discord SDK, login, posts, chat, or profiles exist in the app.
- YouTube hosts one optional bankroll-management educational video.
- National Council on Problem Gambling hosts an optional help-resource link.
- GitHub hosts the public privacy policy and support page.
The app itself has no ads, analytics, tracking, AI service, payment processor, sportsbook integration, developer-operated API, or user-facing notification feature. Apple may deliver silent background notifications solely to keep the user’s private iCloud tracker records in sync.

6. REGIONAL DIFFERENCES
Core tracker functionality is identical in every region. The external Whop action is shown only for the United States App Store storefront; other storefronts show an availability explanation. This submission is intended for United States availability only.

7. REGULATED SERVICES / THIRD-PARTY MATERIAL
The app is not a gambling operator or sportsbook. It cannot accept deposits, hold funds, place or transmit wagers, connect to sportsbook accounts, or award prizes, and it does not link to any sportsbook. It contains a U.S.-storefront-gated Whop checkout URL with a referral parameter for an optional paid Nuke Sports Bets community membership. Whop handles the external purchase, and the membership does not unlock anything in the app. The app uses Nuke-owned branding, text-only category names, and Apple system symbols; it does not display league, team, or sportsbook logos or protected broadcasts.

## Resolution Center reply

Hello App Review,

Thank you for the opportunity to provide the requested information. We have attached a physical-device screen recording that begins with launch and demonstrates the complete typical flow. We also added the same detailed device, access, external-service, regional, and regulated-service information to the App Review Information Notes field for future submissions.

This build has been simplified to a free manual tracker. It contains no member login, paid in-app content, community feed, sportsbook connection, wagering flow, ads, analytics, or tracking. One optional U.S.-storefront link opens a separate paid community-membership page in the browser; Whop handles the external purchase, and membership does not unlock anything in the iOS app.

Please let us know if any additional test steps or documentation would help your review.
