# ADR-072: Post-Success Claim Recheck (Prove-Time Race Fix)

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-072 |
| **Initiative** | unsorry Phase 3 — coordination correctness |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-18 |
| **Status** | Accepted |

## WH(Y) Decision Statement
**In the context of** the ADR-004 claims branch, where an agent reserves a goal by
pushing `claims/<goal>.<agent>.aisp` first-push-wins and `claim_goal` rechecks the
per-mode cap (prove 1 / translate 2) only when a push is **rejected** (the
#184/#185 rejection race),
**facing** the duplicate-proof root cause behind the post-ADR-064 dead PRs:
because claim files are **per-agent**, two agents claiming the same goal write
**different** paths, so the second agent's push is a **clean fast-forward** —
*not* a rejection — whenever its claims base already contained the first agent's
claim (it fetched after they pushed); the on-rejection recheck never runs, both
pushes succeed, and **both agents prove the same goal**, producing the sibling
`queued/prove/<goal>/<agent>-*` branches that ADR-064/ADR-071 then only clean up
downstream,
**we decided for** adding a **post-SUCCESS recheck** in `claim_goal`: after a
successful push, re-fetch `origin/claims` and re-apply the same per-mode cap that
the rejection path uses; if other agents now meet the cap, **withdraw** (remove
the just-pushed claim via `release_claim`, emit `collision`, return failure) so
the agent does not prove the goal,
**and neglected** a deterministic tie-break to let exactly one racer proceed
(rejected — a recheck that runs before the rival's claim has landed cannot rank
safely, so any "proceed if I look like the winner" rule can let both proceed; the
conservative "withdraw if the cap is met by others" never yields two provers, at
the cost that a tight tie makes **both** withdraw and the goal is simply
re-selected next cycle), and switching to a per-goal lock file or non-per-agent
claim path (rejected — invasive to the claims schema, Gate B, and the reaper; the
post-success recheck reuses the existing cap helper, DRY),
**to achieve** at-most-`cap` provers per goal enforced at claim time — stopping
duplicate proofs at the source rather than sweeping their PRs,
**accepting that** each successful claim now costs one extra `git fetch` +
re-check, a tight race can waste a claim round (re-selected next cycle, never a
duplicate or a permanent stall — the goal stays in the open pool), and the
guarantee is best-effort under infra failure (a failed re-fetch keeps the claim;
the TTL reaper and Gate B remain the backstop).

## Context

Completes the ADR-064 / ADR-071 line: ADR-064 dedups at dispatch, ADR-071 closes
the dispatch stale-snapshot window, and this ADR removes the upstream cause — two
agents proving one goal. The fix is confined to `claim_goal`'s success path and
is hermetically self-tested (`test_claim_post_success_recheck`) against a real
git claims remote where the rival's claim is already in the base so the push is a
clean fast-forward.

## Options Considered

### Option 1: Conservative post-success recheck (Selected)
**Pros:** never two provers; reuses the existing per-mode cap helper; tiny;
symmetric with the on-rejection recheck.
**Cons:** a tight tie wastes a claim round (both withdraw, re-selected next cycle).

### Option 2: Post-success recheck with deterministic tie-break (Rejected)
Let the lexicographic/earliest-ts winner proceed. **Cons:** a recheck that runs
before the rival's claim lands sees only itself and proceeds, so the rival —
which may be the tie-break winner — also proceeds → both prove. Not safe without
a barrier.

### Option 3: Per-goal lock file / non-per-agent claim path (Rejected)
Make the claim push genuinely conflict for the same goal. **Cons:** breaks the
per-agent claim model that translate's cap-2 needs; invasive to the schema, Gate
B, and reaper.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Amends | ADR-004 | Claims Branch — First-Push-Wins | Adds the post-success recheck the per-agent filenames require |
| Relates To | ADR-010 | Affinity-Gap Selection | The cap is the prove/translate claim cap |
| Completes | ADR-064 | Goal-Level Dispatch Deduplication | Removes the upstream cause of the duplicates ADR-064/071 clean downstream |
| Relates To | ADR-071 | Fresh Pre-Create Dedup Re-check | Downstream sibling-branch cleanup |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | SPEC-072-A — Post-success claim recheck | Specification | specs/SPEC-072-A-Post-Success-Claim-Recheck.md |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-18 |
| Accepted | unsorry maintainers | 2026-06-18 |
