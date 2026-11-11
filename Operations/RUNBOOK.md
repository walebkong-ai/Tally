# Solvry launch operations

Firebase project: `solvry-walebkong`. Site project: `appgprj_6abd6478c7a081918572401c942f954d`. Firestore stays on **Spark with billing disabled**, as requested. Sites access stays **custom**. These controls do not change the hosting audience or link a billing account.

## Watch usage and receive warnings

Owner email: `walebkong@gmail.com`. Four enabled Cloud Monitoring policies warn at **40,000/47,500 document reads** and **16,000/19,000 document writes**, using 24-hour alignment windows. They are conservative operational estimates; the free allowance resets around Pacific midnight, index/security-rule billing and metric counts can differ, and metrics/email can lag. A sudden spike can exhaust quota before an alert arrives. Native Firebase billing budgets are not configured because there is no billing account.

The owner confirmed receipt of the one-time delivery-canary email; that temporary policy was removed afterward. Exact permanent resource names and dashboard are in [monitoring-state.json](monitoring-state.json). Run `node Scripts/monitoring.cjs status` to read actual recent document metrics, or use the Firebase Usage page. Dashboard title: **Solvry launch operations**. `node Scripts/monitoring.cjs apply` is idempotent and refuses to apply this Spark setup if billing has been enabled. Cloud Monitoring currently publishes metric-alerting charges starting no sooner than September 2027; review pricing before then. No paid managed backup, PITR, Cloud Functions or Analytics was activated.

## Inspect operational errors

`node Scripts/diagnostics.cjs` reads owner-accessible backend summaries using the existing Firebase CLI credentials. Its output uses only UID suffixes and safe diagnostic fields. Firebase Console → Firestore → `clientHealth` is another operator view. This is a small first-party health summary, not full stack-trace reporting or an Analytics deployment.

Signed-in clients record fixed counters for sessions, score saves, sync results, friend actions and explicit import rejections, plus the latest allowlisted error code/category/app section and release. No error message, stack, URL, email, score, answer, note or pasted result is transmitted. Clients batch into one owner-readable record per account, at most once every five minutes. Self-reported counters are approximate and never used for billing, ranking or authorization. Guest sessions are not uploaded; failures before modules load and reports blocked by a total Firebase outage are coverage limits. Queued reports remain isolated per account; reports older than seven days are discarded at the next account load, event or upload attempt. Closed browsers can retain the stored copy until reopening. Account exports include the cloud summary, and deletion removes both cloud/local diagnostics. Health records otherwise remain until operator removal; Spark TTL is not enabled.

New rules validate fixed schemas, owner scope, timestamps, size/range limits and the write interval. The emulator suite exercises peer/anonymous denial, schema pollution, malformed updates, rate limits, deletion locks and the existing score protections. Rules were also syntax-validated and fetched back after deployment for comparison. Review them with the other access controls before widening the audience.

## Back up and restore

The macOS user job **com.solvry.local-backup** runs daily at **03:00 local time**, with a coalesced run after wake from sleep. It requires this Mac, the logged-in user, network access and a valid Firebase CLI session. It is a local backup schedule, not an always-on cloud service. `node Scripts/install-backup-job.cjs` installs/verifies the job; the installed plist is in the user’s `Library/LaunchAgents` directory. `node Scripts/daily-ops.cjs` runs it manually. It creates an encrypted copy, verifies decryption, removes only this job’s expired backup files after fourteen days, and records usage/status.

Backups and the encryption key live in the ignored, private `.local-ops` directory in the release checkout. Directory mode is700; key and backups are600. AES-256-GCM authenticates a compressed snapshot. Preserve the key separately in secure storage and copy encrypted backups off this Mac to protect against loss of the computer. Do not commit, upload to Sites, paste or email the key or plaintext data. The current setup does not create an independent off-device copy.

The backup covers a fixed-read-time Firestore snapshot, live rule source/release, indexes and separately fetched Google-only sign-in identity metadata. It excludes credential tokens/passwords and is not atomic across Firestore/Auth. Adding password/other providers makes the exporter fail rather than save an incomplete identity backup. Creating a snapshot uses normal Spark document reads and has a10,000-document safety ceiling.

Check `.local-ops/last-run.json`, `scheduler.log` and `scheduler-error.log` for job health. A failed job is recorded locally; backup-failure email is not configured. `launchctl print gui/$(id -u)/com.solvry.local-backup` verifies the loaded schedule. To stop this specific job, use `launchctl bootout gui/$(id -u)/com.solvry.local-backup`; keep the encrypted copies and key until their retention is intentionally changed.

### Restore drill

Start the dedicated loopback emulators with `Operations/restore-emulators.json`, project `demo-solvry-restore`, then run `node Scripts/backup.cjs restore-emulator <encrypted-backup>`. The command refuses production project IDs, remote hosts and nonempty targets. It restores into Firestore8099 and Auth9098, checks all document fields by hash and Google identity IDs/metadata, and performs zero production writes. The completed drill restored20 documents and2 identities. Managed cloud backups/restores and PITR remain unavailable under the selected Spark setting.

## Roll back a release

1. Stop additional deployment work and confirm current audience/version with Sites `get_site`. Preserve the audience. Export/check a current encrypted backup before any data migration.
2. Read [rollback.json](rollback.json). Version65 is the beta-verified schema2 fallback, with saved-version ID, full source SHA and archive fingerprint recorded. Check it with `get_site_version`; use that saved ID unchanged.
3. Call Sites `deploy_site_version` for the saved fallback. A deploy changes production. Inspect nonterminal deployment status until succeeded/failed and confirm the returned version ID. Record the incident and deployment ID.
4. Smoke-check sign-in, read-only score views and Add score. The fallback uses the same account schema2. Retain the current additive diagnostics rules; old clients simply do not report diagnostics. Never roll back to a version before the account-safety migration.
5. Redeploy the intended fixed saved version using its exact ID and verify success again. The launch-operations release is checked by a live fallback-and-return drill; deployment IDs and measured duration are recorded in the launch QA report.

An application rollback does not restore Firestore or undo user edits. Rules/config/data changes require a compatibility review; the backup script deliberately offers no production restore switch. Use the tested emulator restoration path to inspect a recovery copy before making a production recovery plan.

## Parser audit changes

QA-02: Wordle accepts exactly one complete score header; supplied grids must match row length/count and terminal solve/miss. Header-only imports remain supported. QA-03: Connections rejects malformed rows and play after a terminal result rather than dropping rows. QA-04: Strands recaps have no reliable total-word proof, so imported recaps are Played with an explicit warning; a user can confirm Solved manually. Unverified Strands entries receive no completion points. QA-05: partial puzzles do not increase completion totals, while completed scored rounds remain eligible. Existing saved results are not silently rewritten.

Official references: [launch checklist](https://firebase.google.com/support/guides/launch-checklist), [Firestore quotas](https://firebase.google.com/docs/firestore/quotas), [managed backup requirements](https://firebase.google.com/docs/firestore/backups), [budget alerts](https://firebase.google.com/docs/projects/billing/budget-alerts), [Cloud Monitoring pricing](https://cloud.google.com/products/observability/pricing).
