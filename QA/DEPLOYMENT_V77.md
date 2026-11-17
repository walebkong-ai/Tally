# Prompt 3 controlled release — Solvry v77

Publication confirmed November 17, 2026 at **16:51:40 America/Toronto** (21:51:40 UTC).

## Release identity

- Live URL: https://solvry.walebkong.chatgpt.site
- Version: **77**
- GitHub tested application/review commit: `a85c5477bef97431713c27da1f90046d3a1a09e4`
- Sites source commit: `162ec37eba4cf19fcbd22255c9ddff4f61708293`
- Saved version: `appgprj_6abd6478c7a081918572401c942f954d~appgver_b3ee14ab8bc88191bbff02f62939ca67`
- Successful deployment: `appgdep_6afccc60e1148191905a8e267827a7a5`
- Server-normalized deployment archive: `sha256:e6d8c9ced5e8e76ce9fd7e32fa0865149924825c09120c69d1e7c62c9154678d` (19 files, 604,160 bytes)
- Local transport archive: `sha256:6bfd2e43b72a3eb0baa01d5539966f04fca017d2e1c49a55e9f48314913f255a`; the server normalizes the packaged archive, so its fingerprint differs.
- Existing **custom** invited audience and exact access-policy revision/set preserved. No access expansion, billing change or Firebase deployment.

GitHub and Sites have separate histories. All 23 copied source/document files matched byte-for-byte (22 release changes plus the existing v76 report); all 18 generated files matched. The Sites helper rebuilt the production output, passed all 268 application tests, committed/pushed its exact source and packaged the matching static files. Native `get_site_version` after publication confirmed source, archive and deployment ID. This report is a subsequent documentation-only GitHub commit; it does not change the deployed app commit above.

## Assessment

| Area | Final result |
|---|---|
| Batch correctness and persisted-data recovery | **PASS** after blocker fixes |
| Sync with actual Auth/Firestore SDKs | **PASS in isolated emulators**; **CONDITIONAL PASS** for production verification |
| Mobile and clipboard | **CONDITIONAL PASS** — iOS Simulator manual input/copy/paste observed; no physical iPhone or native permission-denial completion |
| All 19 parser formats and rule-compatible payloads | **PASS** after blocker fixes |
| Controlled invited release | **CONDITIONAL PASS**, published successfully; broader production verification remains |

No remaining demonstrated code release blocker. The review reproduced and fixed date-correction failure, loss of an earlier journal-only save, malformed legacy scalar imports, missing Connections puzzle IDs and unsyncable recaps above the existing 100-row limit. Detailed evidence, root causes, compatibility and remaining limits are in [PROMPT3_PRODUCTION_REVIEW.md](PROMPT3_PRODUCTION_REVIEW.md).

## Verification completed

- Optimized Swift production generation and generated JavaScript/module syntax passed.
- **268 application tests**, **27 existing Firestore rule tests**, **3 Auth/Firestore integration tests** passed with zero failures. The integration tests contain the connected/offline/reload/retry/two-device-conflict/account-switch scenarios and all 19 real SDK payload checks; these counts are top-level tests, not scenario counts.
- Actual independent Firebase Auth emulator sessions read the same user's scores; another account was denied private records. Offline writes stayed local until recovery; explicit conflict resolution advanced revisions once, and retries did not duplicate them.
- The v76 rule source and live release matched before and after publication:
  - Ruleset: `projects/solvry-walebkong/rulesets/0ab73c61-45eb-49d0-9d8a-6d8786b5acc1`
  - SHA-256: `f555211b4ae54a53f672629c8b89b64a91a9203e421fd2530a564da35006b513`
- Native deployment result was **succeeded**, with no failure message. Recent Sites worker error logs returned **zero events**.
- Anonymous, credential-free GET requests to `/`, `app.js?v=46`, CSS and the three checked modules all returned **401 Unauthorized**, consistent with the unchanged invited-access gate. This verifies denial, **not** successful live asset hash comparison.
- Existing production browser session was inspected read-only and contained real user history. No score was entered, replaced, removed, re-dated or synchronized as a production test; its sign-in state was left untouched.

## Production verification stopped at authenticated testing

A suitable isolated production account/session was not available. The existing signed-in session contains real history, and the user prohibited altering real user records during testing. It was therefore not reloaded into the new app or used for writes/account switching. Anonymous HTTP access could not retrieve the protected files for a byte comparison. No bypass token was created and no security/access restriction was relaxed.

**Not claimed as completed:** new-version production UI preview/clipboard smoke, fresh Google OAuth, save → confirmed cloud sync → reload, second-session retrieval or production conflict resolution. These need a disposable authorized Solvry profile/session. The emulator evidence does not close those production checks. iOS testing was Safari in the native iOS 26.4 Simulator runtime, not a physical iPhone; its paste permission sheet could not be reliably operated through available UI controls. A mocked denied/missing Clipboard API was tested independently and direct paste remained usable.

Before widening the audience, sign in with isolated test accounts and perform additive test saves only on unused game/date pairs. Verify all the above paths, decline clipboard permission on a physical iPhone and confirm manual paste, and keep existing real-user records unchanged. Existing v76 production friendship verification limits also remain as documented; this importer release did not exercise or change real friendships.

## Rollback instructions

Prefer the prior **v76** saved client:

`appgprj_6abd6478c7a081918572401c942f954d~appgver_d8879f726fc481919f2e1e3e61f9a55d`

1. Read current Sites access/version and fetch that exact saved version. Confirm its source is `78bc7f3acf4aade910ffe8e79e7a93b6293e4c3a` and archive is `sha256:c42217a39f961bdac6302106dae72c68dbf66b6929bd68150ac05fa7c9525b4e`.
2. Call Sites `deploy_site_version` with the same project ID and that saved v76 ID. Preserve the current custom audience. Poll only if the response is nonterminal; verify success and returned saved version.
3. Smoke-check read-only views and validation. **Do not roll back Firestore rules or restore/delete user data.** v76 reads the same account/local-journal shapes. It contains the inherited journal/parser defects fixed here, so prefer a targeted fix forward when feasible.
4. To return to v77, deploy its exact saved version ID above and verify source/archive/deployment status again.

Rollback is a client publication, not a database restore. No rollback mutation was performed during this review.
