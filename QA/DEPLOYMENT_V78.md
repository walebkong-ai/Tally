# Today dashboard controlled release — Solvry v78

**CONDITIONAL PASS — published successfully** on November 17, 2026 at **21:18:48 America/Toronto** (November 18, 02:18:48 UTC). No demonstrated code release blocker remains in the tested scope. Fresh production Google OAuth, cross-device write testing and native-iOS verification remain outstanding.

## Release identity

- Live URL: https://solvry.walebkong.chatgpt.site
- Version: **78**.
- GitHub tested application/review commit: `59799a5ce68c14948ad3028b517610343f07d42e`.
- Pushed Sites source commit: `44ebb902d8826dd9a81cabf6ee32c695af777f40`.
- Saved version: `appgprj_6abd6478c7a081918572401c942f954d~appgver_1f50db279ed4819189ba94a11767ccca`.
- Successful deployment: `appgdep_6afd0b01d800819188008c0ade38c968`.
- Server-normalized archive: `sha256:6a57d45de8e05dc5cd080b5e604a39273faba4373ff76ae2b21d809bf841e956` — 20 files, 624,640 bytes.
- Local transport archive: `sha256:f60f4f6c4caa18f9e7665c11ac80a776f917897e4d5d957ffd7f93cf88d384f0`.
- Cache identifiers: app `v=47`, CSS `v=42`, dashboard module `v=1`; existing scoring/import/sync modules retained.

The GitHub and Sites repositories have separate histories. All **19 copied source/document/evidence files** matched byte-for-byte, including the existing v77 deployment report; all **19 generated runtime files** matched between the tested GitHub build and the rebuilt Sites checkout. The supported source helper rebuilt the optimized site, passed all 288 application tests, committed/pushed its exact source and packaged that same output. The normalized archive includes the hosting manifest as its twentieth file; macOS tar metadata is not counted as application files.

Both release checkouts were clean before saving/deploying the candidate. GitHub main was verified against the baseline before pushing, and its remote application commit was confirmed afterward. This deployment record and the verification JSON files are a subsequent documentation-only GitHub update, not a new website publication.

## Review corrections and tests

The review added a friend-availability notice for offline cached standings, paused request updates and account readiness. It uses existing state and adds no Firebase reads/writes. New regression coverage exercises those notices. A fourth Auth/Firestore integration test confirms dashboard pin denominators and scores follow actual emulator sign-out/sign-in and offline upload/retry. No unrelated feature or scoring change was made.

- Swift optimized build and generation: PASS.
- Generated app, dashboard and existing dependency module syntax: PASS.
- **288 application tests passed / 0 failed**, rerun in both GitHub and Sites checkouts.
- **27 security-rule tests passed / 0 failed**, dedicated local Firestore emulator.
- **4 authentication/sync integration tests passed / 0 failed**, dedicated local Auth + Firestore emulators. These contain multiple scenarios, not four production Google-login tests.
- Single/batch imports, edit, deletion, pin/unpin, retained unpinned history, failed attempts, current/historical dates and return to Today: checked through the real localhost UI with synthetic guest records. No production records used.
- Midnight/visibility-return rollover, DST/month/year/time-zone boundaries, pending/error indicators, privacy and account isolation: generated-controller/module and emulator regressions passed.
- Chrome responsive widths **320, 390, 768, 1440** observed; no horizontal overflow with six pinned cards. In-app-browser 390-pixel actions measured 44 pixels tall. Temporary viewport overrides were reset.
- Native iPhone 17 / iOS 26.4 Simulator was present, but stale/locked/unavailable UI controls prevented verified navigation/testing. No fresh native Safari or physical iPhone success is claimed.

Detailed scope, source review and remaining limitations: [TODAY_DASHBOARD_PRODUCTION_REVIEW.md](TODAY_DASHBOARD_PRODUCTION_REVIEW.md). Screenshots: [mobile with synthetic saved/failed results](today-dashboard/release-mobile.png), [desktop Chrome lineup](today-dashboard/release-desktop.png).

## Production verification

Confirmed:

1. Native Sites deployment returned **succeeded**, no failure message. Fetching the saved version afterward confirmed version 78, the exact source SHA, archive fingerprint and deployment ID above.
2. The existing **custom invited audience** and exact policy revision/set remain unchanged (revision 2). No access expansion, Firebase deployment, billing change, token rotation or data migration.
3. Read-only authenticated static requests used the existing owner-access token returned by Sites, through hidden stdin/in-memory headers. No site-access token was generated or rotated, no credential was saved, and cross-host redirects were blocked. These requests fetched only static files and did not execute a Firebase client.
4. All **16 non-HTML runtime assets** returned 200 and matched the tested SHA-256 exactly, including `app.js`, CSS, `dashboard.mjs`, importer, scoring, sync/account modules and images. HTML URLs redirect to canonical extensionless paths; their final responses were 200.
5. The three HTML files are not raw byte-identical because the edge adds one **1,114-character inline script** per response. Structural comparison found only that insertion, with the original application HTML unchanged. The homepage insertion contains the fixed `/cdn-cgi/challenge-platform/` and `__CF$cv$params` markers identifying the Cloudflare challenge bootstrap; dynamic values were not recorded. The live homepage contains `app.js?v=47`, `styles.css?v=42` and the new progress markup. This hosting injection was investigated rather than counted as an exact HTML hash match.
6. Credential-free access returned **403**, preserving denial by the invited-access gate. This is not a public-access success claim.
7. Recent Sites worker error logs (15-minute window, checked twice after publication) returned **zero events**.
8. Live Firestore rule read-back before and after deployment stayed at `projects/solvry-walebkong/rulesets/0ab73c61-45eb-49d0-9d8a-6d8786b5acc1`, SHA-256 `f555211b4ae54a53f672629c8b89b64a91a9203e421fd2530a564da35006b513`.

Verification records without tokens or user records: [asset hashes](today-dashboard/live-asset-check.json), [HTML structural comparisons](today-dashboard/live-html-check.json), [inline-script marker verification](today-dashboard/live-inline-check.json). The raw asset report correctly records HTML hash differences; the structural records explain them. They are not failures of the published application source comparison.

Not completed / not claimed:

- Fresh production browser runtime smoke, Google OAuth, account switching, save → confirmed cloud sync → second-device retrieval, offline production retry or real-friend lifecycle checks on this release.
- Production edit/delete tests. The available browser session was signed in with real history; it was inspected read-only and left untouched. It was not reloaded or used as a disposable test account.
- Native Safari, physical-iPhone touch/keyboard/clipboard permission or assistive-technology verification.

These checks require an isolated authorized production profile/session and, for native-mobile verification, functioning simulator controls or a physical device. Stop those test paths until that environment exists; do not reuse real user records or infer production OAuth/sync success from emulator results. Local browser error logs were empty during checked interactions; this does not prove the fresh production client has no browser errors.

## Performance observations

Same synthetic VM benchmark as implementation: 1,095 days of history, six pins, fifty measured dashboard renders after warmup. Review median **1.448 ms**, p95 **2.113 ms**, six visible-catalog constructions/render. v77 baseline was median **16.052 ms**, p95 **16.903 ms**, 2,201 constructions/render. This measures dashboard calculation/HTML strings only, not browser layout, full-app startup or production network latency.

No new Firestore requests or persisted progress counters. Existing friend refresh/history queries and self-reported scores remain inherited scaling/trust limits. Rendering a long user-selected pin list can still require scrolling.

## Exact rollback procedure

Use the immediately previous verified **v77** complete saved client:

- Version ID: `appgprj_6abd6478c7a081918572401c942f954d~appgver_b3ee14ab8bc88191bbff02f62939ca67`.
- Source: `162ec37eba4cf19fcbd22255c9ddff4f61708293`.
- Archive: `sha256:e6d8c9ced5e8e76ce9fd7e32fa0865149924825c09120c69d1e7c62c9154678d`.

1. Read current Sites audience/version. Fetch that exact saved v77 version and reconfirm its source/archive above.
2. Call Sites `deploy_site_version` with project `appgprj_6abd6478c7a081918572401c942f954d` and that exact v77 saved version ID. Preserve the existing audience. Poll only a nonterminal deployment until succeeded/failed; verify the returned saved version and source.
3. Verify static assets/read-only views and check logs. **Keep current Firestore rules, account schema and user data. Do not restore or delete data.** Both clients use the same persistence shapes; no migration is needed.
4. To return to the reviewed v78 client, deploy its exact saved version ID recorded above, then reconfirm success/provenance and checks.

No production rollback flip was performed during this review; the exact saved fallback artifact and unchanged schema compatibility were confirmed. Rollback changes the complete website, not the database. Retain current backups independently.
