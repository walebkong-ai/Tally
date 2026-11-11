# Solvry release verification and launch readiness

Updated November 11, 2026. This is the public summary of local release and beta evidence; it omits participant identities, account identifiers, scores, private answers/notes, raw reports, screenshots, and backup material.

## Release and scope

- Published application: **v67**, through OpenAI Sites.
- Sites source checkpoint: `45bf30f4133344b7c86215ec618b755332d62b46` (a separate source history from this repository).
- Website: https://solvry.walebkong.chatgpt.site/.
- Access: custom/invite-only; no custom domain attached at this checkpoint.
- Backend: Firebase Google Authentication and Toronto Firestore, Spark with billing disabled.
- Assessment: core invited-beta scenarios passed; additional checks remain before a small public beta and broader promotion.

## Application and permissions

Recorded v67 validation passed 139 application tests and 20 Firestore emulator tests, generated JavaScript/module syntax checks, native rule validation, and a comparison of deployed rules with tested source. Automated coverage includes account storage isolation, revision conflicts, score date correction/deletion, account deletion locks, private/shared projection separation, reconnect recovery, and bounded/redacted operational diagnostics.

Before the November 11 GitHub upload, the source was rebuilt in this repository and the 139 app tests and 20 isolated Firestore permission tests passed again. The generated `dist/app.js` SHA-256 is `3d0d00af520da4ba7054d40bd42d4d0475c1fa78918432cedfd7f49e6fcbe89b`, matching the verified v67 served artifact. Application source, rules, Firebase configuration, and dependency lockfile match the release checkout. The upload scan found no private key, saved authentication token, service-account credential, or private beta fixture identifiers/content in the candidate files; the embedded Firebase browser API key is intentionally public client configuration.

The two-account, user-assisted beta used computer Chrome and confirmed iPhone Safari. Completed scenarios included:

- Real Google sign-in and distinct private account histories.
- Switching between the two accounts and guest mode without importing the other account's private data.
- Sending and accepting a friend request after a persistence defect was reproduced and fixed.
- Private records denied to the peer; shared scores readable only in the intended relationship state.
- Intentional answer reveal followed by removal of the answer from the shared projection when sharing was turned off.
- Removal revoking new score reads in both directions.
- An offline device save, reconnect/retry after a reproduced recovery-status defect was fixed, and same-account read-back on the computer.

These results combine user observations, captured sanitized permission reports/screenshots, and independent administrative read-back. They are not a fully automated cross-device production test. Previously downloaded or cached data cannot be recalled by removing a friendship.

## Parser audit

The remaining audited Wordle, Connections, Strands, and partial-completion defects were corrected with regression coverage. Malformed/contradictory shares are rejected, unknown Strands completion is saved as Played with a warning until manually confirmed, and partial puzzle attempts do not increase completion totals. Existing user history was not silently rewritten. Representative parser fixtures do not guarantee compatibility with future publisher format changes.

## Operations

- Four active read/write quota-warning policies at 80%/95% of daily free allowances. Owner email delivery was tested with a temporary canary, then the canary was removed. Operational metric windows differ from exact quota accounting, and metrics/email may lag. Other quotas are not covered.
- An operational usage dashboard and account-scoped health reporting are deployed. Health summaries exclude result content, free-form messages, stack traces, emails, and URLs. Production client delivery has not been separately captured since release.
- AES-256-GCM local backup creation and a daily 03:00 local macOS schedule with 14-day retention were tested. A restore into fresh loopback Firestore/Auth emulators recovered all 20 documents and both Google identity records with matching hashes/metadata and zero production writes.
- A final v67 → v65 → v67 application rollback drill completed in 41 seconds, with authenticated served-artifact hash checks. The compatible database/rules remained in place; application rollback is not a production data restore.

Backups depend on the operator's Mac, logged-in user, network, and Firebase CLI session. Backup copies and their key are local; no independent off-device copy or backup-failure email is configured. Managed cloud backups, PITR, and billing budgets remain off under the selected Spark setup. See [Operations/RUNBOOK.md](../Operations/RUNBOOK.md).

## Remaining launch checks

1. Exercise export, score date correction/deletion, and complete account deletion on a disposable live account; verify cloud cleanup and stale-session protection.
2. Exercise simultaneous conflicting edits across two devices and verify both resolution choices. Revisit the earlier date-entry and stale-score observations, whose causes were not reproduced.
3. Run fresh onboarding with an independent tester. Android/mobile Chrome, duplicate/declined/cancelled/repeated friend requests, and request delivery without reload still need live coverage.
4. Place encrypted backups off the operator's Mac and preserve the decryption key separately in secure storage.
5. Confirm a production diagnostic report arrives without private content.
6. After domain/DNS/HTTPS and sign-in configuration, verify the intended public pages and private-data restrictions from a fresh signed-out browser when public access is enabled.
7. Observe actual beta usage before wider promotion; no load/capacity test for a traffic surge has been completed. Cold offline startup, offline reload, storage eviction, and long offline intervals remain untested.

## Repository boundaries

This repository includes reproducible source, brand assets, test fixtures, public Firebase client configuration, rules, lockfiles, and operator tooling. Participant reports and screenshots remain in the private local QA archive. Runtime data, administrator credentials, account exports, encrypted backups/keys, dependency directories, and generated site output are not published here. Source updates do not automatically deploy the website or Firebase configuration.
