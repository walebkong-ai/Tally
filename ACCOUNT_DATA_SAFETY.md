# Account and data safety

Implemented 2026-11-09; backend activated 2026-11-10.

Production Firebase project: `solvry-walebkong`. The `(default)` Firestore database uses Standard edition in Toronto (`northamerica-northeast2`), is eligible for the free tier, and has deletion protection enabled. Billing is not linked. Google sign-in is enabled; Apple sign-in has not been configured and is not offered in the UI. The Site remains at `https://solvry.walebkong.chatgpt.site` with its existing audience.

The deployed Firestore rules were fetched and compared byte-for-byte with the tested committed rules before the admin-only `system/security` activation marker was created with `accountDataVersion: 2`. The browser includes the registered public Firebase web configuration. Service-account credentials are not included.

## Account and score controls (2026-11-10)

Account offers a fetched account-plus-device JSON export and a clearly labeled device-only export. Exports allowlist identity fields, retain own pending/conflicting edits, include current private records and cloud requests when fetched, and exclude sign-in credentials and cached peer score data. The public notice is available at `#privacy`, with its review copy in [PRIVACY_NOTICE.md](PRIVACY_NOTICE.md).

Score deletion removes the active own result and syncs revisioned tombstones. Old browser journals can retain prior score details; the notice discloses this. Date correction keeps destination scores, checks source/destination revisions, and atomically writes both private results and both shared projections. Cloud date moves require connectivity; guest/personal device-only scores can move locally. Printed daily dates are validated. Changes made during a score operation cannot be silently submitted by another form.

Account deletion is bound to the specific account shown in the confirmation. It requires typed confirmation and Google reauthentication. An owner-only `accountLifecycle/{uid}` record locks all new/updated account data and revokes friend score reads before cleanup starts. `deleting → deleted` is irreversible for clients; server timestamps and recent authentication are enforced. Owner cleanup alone can remove profiles, requests, shared scores, and private records. Shared paths are removed before their private directory records, in bounded batches, so interruption is resumable. The sign-in identity is deleted last. This is client-driven cleanup: the page must remain open; interrupted cleanup stays locked and offers Resume account deletion on the next sign-in. No background worker or paid Firebase service was added.

The minimal account-ID lifecycle marker with state/timestamps is retained to reject old sessions. Account data on the current device is purged; other online sessions purge when they observe the marker, while offline devices may retain copies until reconnecting. Guest storage and other accounts are preserved. Other people’s cached copies, exported downloads and provider backups/logs are separate. Deleting an identity directly in the Firebase console bypasses this app cleanup workflow and requires trusted administrative cleanup.

The sync indicator distinguishes device-only, offline, pending, loading, syncing, conflict, error, and confirmed states. Account reload/retry uses server reads; a confirmed state means eligible local changes match the last acknowledged copy, rather than asserting that no other device can have changed the account. Personal custom-game data remains local.

## Storage boundaries

- Browser history uses `solvry-state-v2:guest` while signed out, and `solvry-state-v2:account:<encoded Firebase UID>` after Firebase verifies the account. Signing out restores guest history. An account switch clears input drafts and ignores callbacks from the previous account.
- Sign-in never imports the guest's scores. **Account → Import device history** requires confirmation, copies only missing own scores, retains existing account scores, and hides imported answers. Personal custom games remain personal. Never import another person's history on a shared device.
- Legacy `solvry-state-v1` and `tallyo-state-v1` keys remain intact. Unscoped signed-out history can seed guest storage. Legacy signed-in history is recoverable only through explicit import into the matching verified UID. Ownership cannot be inferred safely for a mixed legacy history.
- Each tab writes a durable journal before updating its cache. Independent record edits merge; competing edits retain both copies for review in Account. Conflict decisions and cloud revision acknowledgments survive cache-write failure. Unreadable storage blocks edits rather than replacing the stored copy.

Browser namespaces prevent accidental cross-account mixing; they do not encrypt localStorage or protect it from another person with access to the same browser profile. Sign-out does not erase saved account data. Use separate browser/OS profiles on shared devices.

## Firestore layout

| Path | Contents and access |
| --- | --- |
| `privateUsers/{uid}/records/{id}` | Owner-only profile, own result details, friend references, pins and explicitly shared custom definitions. Answers, notes, raw pasted results and grids stay here. Personal custom definitions/results stay on the device. |
| `profiles/{uid}` | Signed-in account discovery: name, handle and normalized handle only. Email, history and friend lists are excluded. |
| `sharedScores/{uid}/games/{gameId}/results/{date}` | Accepted friends can read the score, result, source and answer-sharing flag. An answer is included only when its owner explicitly enabled sharing. Notes, raw pastes and grids are forbidden. Color Daily may include its verified date. |
| `friendRequests/{pairId}` | Participants can read and perform allowed request transitions. Both must consent before score access. Removing the connection revokes subsequent reads. |
| `accountLifecycle/{uid}` | Owner-only minimal deletion lock; clients cannot remove or reset it. No profile or score payload. |
| `system/security` | Admin-only activation marker, readable by signed-in clients. |
| Legacy `users/{uid}` and all undeclared paths | Client access denied. |

Custom-game score access additionally requires both people to have joined the same definition and enabled friend sharing. Turning sharing off revokes reads as soon as the private sharing marker commits. Publication stages the definition as personal, writes its scores, and enables friend access last. Previously copied data cannot be recalled.

Each cloud record has a revision. A transaction compares its expected revision and atomically updates the private record and minimal public projection. A stale same-record edit becomes a reviewable conflict, including when Firestore rules reject a stale transaction before the SDK retries. Independent records do not replace a whole account document. Edits made during an in-flight save remain pending. Deletions use revisioned tombstones.

## Activate a new Firebase backend

1. Create a Firebase project and Firestore database. Register the web app, configure the intended Authentication providers, and authorize the Site's actual domain. Start with test accounts.
2. Install the pinned development tools with `npm ci`. Authenticate the Firebase CLI using your own account. Deploy the checked-in rules to the explicit project:

   ```sh
   npx firebase deploy --only firestore:rules --project YOUR_PROJECT_ID
   ```

   Do not select permissive test-mode rules. This repository's `firebase.json` points at `firestore.rules`.
3. Using the Firebase console or a trusted Admin SDK, create document `system/security` with numeric field `accountDataVersion: 2`. Client rules forbid creating or changing this marker. Set it only after the rules deployment succeeds.
4. Supply the registered Firebase web configuration as `window.SOLVRY_FIREBASE_CONFIG` before `app.js` loads. Local testing may use JSON in `solvry-firebase-config`. Web configuration is public client configuration; never put service-account credentials or an Admin SDK key in the browser or source repository. This static Site does not automatically consume hosting environment variables.
5. Verify real provider sign-in, sign-out, a second account in the same browser, explicit guest import, accepted-friend access, hidden/revealed answers, unfriend/unshare revocation and competing edits from two devices before inviting users. The emulator does not certify OAuth provider or live-domain configuration.

The app requires the activation marker and does not fall back to the old mixed cloud document. Without backend configuration it remains device-only; a configured project without the marker leaves edits in that account's separate device storage and reports setup as incomplete.

### If a legacy backend is discovered later

Do not enable the marker immediately. Back up its data, deploy restrictive rules to stop old clients, and migrate using trusted admin tooling. Review ownership; an old mixed document may already contain someone else's local history. Split verified own results into private records and allowlisted projections, keep hidden answers/raw pastes private, and validate counts and access with test accounts. Legacy remote migration is intentionally not automated by the browser and is not included in this change. Retain the backup until ownership and restored history are verified.

## Verification

From this repository directory:

```sh
swift run solvry-site
node --check dist/app.js
npm test
npm run test:rules
```

The emulator suite requires a supported Java runtime and uses only `demo-solvry-safety`, with Firestore on port 8089. It checks owner isolation, accepted-friend reads, projection field restrictions, hiding an answer, atomic revision enforcement, custom-game revocation, request authorization, missing activation marker, denied legacy paths, and actual concurrent SDK transactions. Application regression tests cover account namespaces, journal recovery, conflict decisions, stale callbacks, import/ranking behavior and privacy projections. Browser QA uses synthetic identities and data; no real user account or production database is involved.
