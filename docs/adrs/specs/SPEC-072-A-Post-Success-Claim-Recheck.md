# SPEC-072-A: Post-Success Claim Recheck

Implements: [ADR-072](../ADR-072-Post-Success-Claim-Recheck.md) | Status: Accepted | Updated: 2026-06-18

Amends the claim protocol (ADR-004). Change is in `swarm/agent.sh` `claim_goal`.

## 1. Problem

Claim files are per-agent (`claims/<goal>.<agent>.aisp`). Two agents claiming the
same goal write different paths, so the second push is a **clean fast-forward**
(not a rejection) whenever its base already contained the first claim. `claim_goal`
only rechecks the cap **on rejection**, so both pushes succeed and both agents
prove the goal — the prove-time race that creates sibling `queued/prove/*`
branches.

## 2. Fix: recheck after a successful push

After a successful `git push origin claims`, before returning success:

```
git -C "$CLAIMS_WT" fetch -q origin claims          # refresh (now has rivals + ours)
git -C "$CLAIMS_WT" reset --hard -q origin/claims    # keeps our pushed claim
if ! py_helper "$recheck" "$CLAIMS_WT/claims" "$goal" "$AGENT_ID"; then
    release_claim "$goal" || true                    # remove our just-pushed claim
    emit_event collision "$goal"
    return 1                                          # do NOT prove
fi
emit_event claimed "$goal"; return 0
```

`$recheck` is the same per-mode helper the rejection path uses:
`prove-claimable` (cap `PROVE_CLAIM_CAP=1`) in prove mode, `claimable`
(`TRANSLATE_CLAIM_CAP=2`) otherwise. It exits non-zero when **other** agents'
live claims meet the cap. Our own claim is not counted against us.

The whole block is guarded by `&&`, so a failed re-fetch/reset skips the recheck
and keeps the claim (best-effort; the TTL reaper and Gate B remain the backstop).

## 3. Why conservative (no tie-break)

If the recheck runs before a rival's claim has landed, it sees only our own claim
and proceeds. A "proceed if I am the tie-break winner" rule would then let the
later-landing rival — possibly the winner — also proceed, yielding two provers.
So the rule is purely "withdraw if others meet the cap": at most one prover, with
the only cost that a tight tie makes **both** withdraw and the goal is re-selected
next cycle (never a duplicate, never a permanent stall — it stays in the open
pool).

## 4. Test

`test_claim_post_success_recheck`: a live rival claim is placed on `origin/claims`
**and** synced into the agent's worktree, so the agent's own claim pushes as a
clean fast-forward (success, no rejection). Assert `claim_goal` then returns
failure, the agent's claim is **absent** from `origin/claims` (withdrawn), and a
`collision` event is emitted. `test_claim_recheck_prove_cap` (rejection path and
translate cap-2 keep-on-success) continues to pass.

## 5. Out of scope

- Deterministic single-winner tie-break (Option 2, rejected).
- Per-goal lock / non-per-agent claim path (Option 3, rejected).
- Downstream dispatch dedup (ADR-064 / ADR-071) — unchanged.
