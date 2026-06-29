# SPEC-099-A: Re-attribute Agent-Owned Pipeline Solver to the Pipeline Owner

Implements: [ADR-099](../ADR-099-Reattribute-Agent-Owned-Pipeline-Solver.md) · Status: Living · Updated: 2026-06-26

ADR-099 adds a `solver≜` re-attribution pass to the idempotent attribution sweep:
a record whose `agent≜` is a declared **agent-owned pipeline** is credited to that
pipeline's owner, correcting `mac-158f` proofs that were landed under a dispatcher's
handle. This spec is the contract. It is **solver-only**: the provider/model
`_RULES` (ADR-079) and the difficulty backfill (ADR-087/088) are unchanged; the new
pass simply composes with them in one sweep.

## 1. Deliverables

| # | Deliverable | Surface | CODEOWNERS? |
|---|---|---|---|
| D1 | `_AGENT_OWNER` table + `correct_solver` pure transform | `tools/repo/relabel_attribution.py` | no |
| D2 | Pass A applies `correct_solver`; third summary line | same | no |
| D3 | Tests: re-attribution, idempotence, unowned-agent safety, one-pass composition | `tools/repo/tests/test_relabel_attribution.py` | no |
| D4 | Workflow header reflects solver now moves for owned agents | `.github/workflows/attribution-relabel.yml` | **yes** (`/.github/` @cgbarlow) |

The `/.github/` workflow edit (D4) is the only code-owned surface, so this PR
additionally requires a human code-owner review (ADR-019).

## 2. Ownership table + transform (D1)

```python
_AGENT_OWNER = {"mac-158f": "ohdearquant"}

def correct_solver(text) -> (text, changed):
    # no-op unless agent≜<x> is owned AND current solver≜ differs from the owner
```

- Matches `agent≜` via the existing `_AGENT_RE`; looks the agent up in
  `_AGENT_OWNER`; rewrites `solver≜<lander>` → `solver≜<owner>` (count=1) via
  `_SOLVER_RE`.
- **Idempotent**: a record already crediting the owner, or whose agent is not in
  `_AGENT_OWNER`, returns `(text, False)`. Every non-owned agent's `solver≜` is
  therefore untouched — this never becomes a general dispatch-rewrite.
- Scope is **agent-level, not engine-level**: it matches `agent≜mac-158f`
  regardless of model, so the lone genuine `claude/sonnet` mac-158f proof is also
  owned by ohdearquant (and already credits ohdearquant, so it no-ops).

## 3. Sweep integration (D2)

In `main()` Pass A, per record: `new, did = relabel_record(text)` then
`new, sdid = correct_solver(new)`. Write once when `did or sdid`. The provider/model
relabel and solver re-attribution thus apply in a **single pass** — a pre-relabel
`mac-158f` record (`provider≜claude; model≜template-*; solver≜<lander>`) becomes
`provider≜python; model≜sympy; solver≜ohdearquant` at once. A third summary line is
printed: `solver re-attribution: {re-attributed|would re-attribute} N record(s)`.

Scan globs are unchanged (`library/index/**`, `packages/unsorry-archive-*/library/index/**`,
`proof-runs/**`), so both proof index records and run telemetry are corrected,
keeping per-contributor run counts consistent with proof credit.

## 4. Idempotence & delivery

No one-shot corpus rewrite ships in the implementation PR. The
`attribution-relabel` workflow (hourly cron + push on the scanned paths +
`workflow_dispatch`) runs `--apply` on `main` and applies the correction, no-opping
once converged — identical to ADR-079/087/088. On the current corpus the dry-run
reports **254** records to re-attribute (cgbarlow 134, perttu 120); the leaderboard
regen then re-balances proof vs dispatch credit downstream.

## 5. Tests (D3)

`tools/repo/tests/test_relabel_attribution.py`:
- `correct_solver` re-attributes `cgbarlow`/`perttu` mac-158f records to ohdearquant
  (agent/provider/model untouched).
- Idempotent; owner record (incl. the `claude/sonnet` case) is a no-op.
- Unowned agents (`claude-web`, `ruvnet-swarm`) keep their solver.
- End-to-end `main --apply`: re-attributes across `library/index` + `proof-runs`,
  corrects a pre-relabel record in both dimensions in one pass, leaves an unowned
  agent's solver, and the second run no-ops (`re-attributed 0 record(s)`).

## 6. Out of scope (follow-ups)

Source-level prevention (stamping `solver≜` from the pipeline operator rather than
the PR lander at submission time); re-attributing any other agent (none declared);
notifying perttu of the standing change.
