# claims/

**Claims do not live on `main`.** They live on the dedicated, unprotected [`claims` branch](../../tree/claims) — see [ADR-004](../docs/adrs/ADR-004-Claims-Branch-First-Push-Wins.md) and [SPEC-004-A](../docs/adrs/specs/SPEC-004-A-Claim-Lifecycle-and-Reaper.md).

To claim a goal: fetch the `claims` branch, add `claims/<goal-id>.<agent-id>.aisp` (schema: [SPEC-003-B](../docs/adrs/specs/SPEC-003-B-Claim-Record-Schema.md)), commit, and push to `claims`. A rejected push means the branch moved — rebase; if a competing claim for your goal appeared, someone beat you: pick another goal. Claims carry a 7200 s TTL; expired claims are reaped by a scheduled job, so a dead agent cannot park a goal.

`main` keeps only this README. Any other file under `claims/` on `main` is a Gate B violation.
