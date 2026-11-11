# Privacy notice

Updated November 10, 2026

## What you save

Solvry tracks the game results you choose to add. Browser storage holds your scores, copied result text, answers, notes, pins, custom games, preferences, local game progress, and recovery copies of edits. It may also cache friends’ previously shared scores and sample data. Guest history and each signed-in account use separate storage. Signing in does not automatically import guest history.

## When you sign in

Google and Firebase Authentication process your sign-in. Solvry receives an account ID, email address, display name, and provider information. Google may also supply a profile photo to Firebase Authentication; Solvry does not use it in scoreboards. Your device keeps account details and sign-in state. Firebase holds your sign-in identity; we do not receive your Google password. Your Solvry name and handle are stored in a directory that other signed-in Solvry users can search.

Eligible account scores, answers, notes, copied result text, result grids, pins, and friend references are saved in owner-only Firestore records. Personal custom-game definitions and scores stay on the device. Shared custom-game definitions and their scores sync after you choose to share them. Making a previously shared game personal stops future sharing, but previously synced private score records can remain until you delete those scores or the account. Some preferences and built-in game progress stay on the device.

## What friends can see

After both people accept a friend request, connected friends can read eligible game scores, dates, completion status, and whether a result was pasted or entered manually. Answers are included only when you turn answer sharing on. Notes, raw pasted results, and grids are not included in friend-visible records. Shared custom games also require both people to join the same game and enable sharing. Friend requests include the participants’ names and handles.

Removing a connection or making a custom game personal revokes future reads after the cloud change succeeds. Previously received, copied, downloaded, or offline-cached information cannot be recalled.

## Hosting, storage, and providers

The website is hosted through OpenAI Sites. Google Firebase provides account sign-in and cloud database services. The current Firestore database is in Toronto, Canada; this does not mean all hosting, authentication, logs, or provider processing takes place in Canada. Providers process technical and security information needed to run their services. This version of Solvry does not include Google Analytics or advertising trackers.

See [Firebase privacy information](https://firebase.google.com/support/privacy), [Google’s privacy policy](https://policies.google.com/privacy), and [OpenAI’s privacy policy](https://openai.com/policies/privacy-policy/).

## Operational diagnostics and backups

Signed-in sessions send an account-linked health summary to owner-only Firebase records: release, update time, fixed activity counters, and the latest error category, code and app section. Reports exclude messages, stack traces, URLs, email addresses, scores, answers, notes and pasted results. Uploads are batched at most once every five minutes. Unsigned sessions are not uploaded. Queued diagnostics older than seven days are discarded when the app next loads, records an event or attempts an upload. A closed browser can retain the stored copy until it reopens; account deletion clears it on this device. Account exports include the fetched health summary. Health records remain until account deletion or operator removal; automatic expiry is not enabled on Spark.

Encrypted operator backups include database records and Google sign-in identity metadata, including email and account IDs. Local backups are retained for fourteen days. Backup availability depends on the operator’s computer and Firebase access; these copies are not managed cloud backups. Data deleted from the live account can remain in backups until they expire. The operator can inspect health summaries and platform usage metrics to run the service. No Google Analytics or advertising trackers are included.

## Your controls and retention

Use Account to download JSON exports. An account export includes the cloud snapshot fetched at that time plus this device’s own scores and unsynced edits; a device export covers the current account or guest namespace and may omit data saved elsewhere. Exports exclude cached friends’ scores and sign-in tokens. Keep downloaded exports private.

Use a saved game’s Change date or Delete score controls to correct or remove a result. Cloud changes are confirmed by the sync indicator. Deleted cloud scores retain a minimal revisioned deletion record without score details to prevent an old device restoring the result. Browser recovery journals can retain previous score details until the account’s local storage is cleared, including through account deletion. Provider logs or backups, where retained, follow the providers’ own policies.

Delete account requires Google reauthentication and an explicit confirmation. The app first locks cloud writes, then removes its profile, requests, shared scores, and private records, and finally deletes the Firebase sign-in identity. Keep the page open until completion. If interrupted, sign in again and resume deletion; the account stays locked rather than silently reporting completion. A minimal account-ID deletion marker with status and timestamps is retained to block old sessions from recreating account data. No score details or email are kept in that marker.

Account deletion clears that account’s browser storage on this device. Other connected app sessions clear their account copy when they observe the deletion marker; offline devices may retain a copy until they reconnect. Guest data, downloaded exports, other people’s copies, and provider logs/backups are separate. Signing out alone does not erase browser data. Use separate browser or OS profiles on shared devices.

## Questions

For questions about Solvry data, contact [walebkong@gmail.com](mailto:walebkong@gmail.com). This notice describes the current app; changes to storage or sharing will be reflected here.
