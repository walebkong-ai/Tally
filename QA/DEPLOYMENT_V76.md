# Prompt 1.5 deployment — Solvry v76

Release date: November 16, 2026 (America/Toronto).

## Confirmed publication

- Live URL: https://solvry.walebkong.chatgpt.site
- Version: **76**
- Saved version: `appgprj_6abd6478c7a081918572401c942f954d~appgver_d8879f726fc481919f2e1e3e61f9a55d`
- Successful deployment: `appgdep_6afba03bc6808191b8ba7d6da064d65f`
- GitHub application commit: `7fbee187f8adf608de03740ccb4027f698363758`
- Sites source commit: `78bc7f3acf4aade910ffe8e79e7a93b6293e4c3a`
- Saved archive hash: `sha256:c42217a39f961bdac6302106dae72c68dbf66b6929bd68150ac05fa7c9525b4e`
- Existing custom audience preserved; no access-policy or billing changes.

The separate repositories have different histories. All 11 files in the correctness release were
compared byte-for-byte between the GitHub and Sites checkouts. Both were clean before publication.
The Sites helper rebuilt, tested, committed, pushed and packaged its source; the saved version's
provenance confirms that exact Sites commit. No private backups, keys, or dependencies were packaged.

## Rules-first deployment

An encrypted pre-release snapshot was created and verified with the existing recovery key. The
read-only inventory contained 24 documents, two Google identities, one relationship pair, no duplicate
pairs, no accepted/removed ambiguity, and `accountDataVersion = 2`. No migration was required.

The native Firebase deployment job reported success without changing the live rules. Read-back
detected this before website publication. The authenticated CLI then deployed only `firestore:rules`;
its log confirmed compilation, upload and release. Direct API read-back matched the tested rule file.

- Live ruleset: `projects/solvry-walebkong/rulesets/0ab73c61-45eb-49d0-9d8a-6d8786b5acc1`
- Rule SHA-256: `f555211b4ae54a53f672629c8b89b64a91a9203e421fd2530a564da35006b513`
- Rules release: November 16 at 19:29:34 Toronto time.
- Website publication succeeded afterward, at 19:30:58 Toronto time.

The rules were tightened, not reverted or loosened. No database documents were deleted.

## Re-run verification

| Check | Result |
| --- | --- |
| Swift package production-site generation | Passed in both checkouts |
| Generated app and scoring-module syntax | Passed |
| Application suite | 192 passed, 0 failed |
| Firestore emulator suite | 27 passed, 0 failed |
| Whitespace and clean-source checks | Passed |
| Saved version/source provenance | Matches tested Sites commit |
| Live rules read-back | Exact tested SHA-256 match |

The build is the existing static Swift generation process; no framework migration or dependency
change was introduced. Expected permission-denied messages in emulator adversarial tests were
asserted denials, not deployment failures.

## Production smoke checks

- Existing owner Google session restored and reached **Changes synced**.
- Manual Mini `00:00` was rejected with the expected positive-time validation message.
- A future date (November 17 while the local date was November 16) failed range validation and did
  not save. Read-back confirmed no future Mini record was created.
- A new, clearly labeled November 16 Mini `00:54` smoke result saved at revision 1, synchronized,
  and remained present after reload. Existing scores were not replaced or deleted.
- The smoke result's note remained private; its shared projection omitted the note and answer,
  and answer sharing was off. The new smoke result is retained, respecting the no-deletion instruction.
- Sign-out succeeded. Fresh Google popup sign-in to the second authorized beta account succeeded
  and reached **Changes synced** with its separate history.
- The second account sent a friend request to the owner; the sent-request list showed one pending
  outgoing request. Read-only database verification confirmed sender and recipient direction.
- Recent Sites worker error logs and the inspected browser tab's error logs were empty.

## Blocked and unverified checks

The automated approval reviewer twice rejected selecting the owner in the Google chooser, stating
that the second account should be the recipient. Read-only request verification established the
opposite: this test sent from the second account to the owner. No alternate login mechanism,
custom token, or administrative acceptance was used to bypass the rejection.

The Google chooser was left open for the user to select the receiving owner account manually.
**The test request remains pending.** Production acceptance, connected peer-score reads, removal,
revocation, and re-invitation were not completed in this run. Their 27-test emulator coverage passed;
that does not establish a completed live two-account test.

Production midnight/suspended-tab rollover and phone behavior were not re-tested here. Automated
rollover/draft/DST/clipboard regressions passed, and the earlier isolated-browser rollover checks
are documented in `Operations/CORRECTNESS_SAFETY_RELEASE.md`.

After the user completes recipient sign-in, verify the expected incoming request, accept it, run
read-only connected privacy checks, remove the test connection, and verify new peer reads are denied.
The pre-test relationship was removed, so return it to the disconnected state after that lifecycle.
Do not delete scores or accounts. Keep the new revocation rules if a client rollback is needed.
