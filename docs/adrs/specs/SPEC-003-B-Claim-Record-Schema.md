# SPEC-003-B: Claim Record Schema

Implements: [ADR-003](../ADR-003-AISP-Coordination-Format.md), [ADR-004](../ADR-004-Claims-Branch-First-Push-Wins.md) · Status: Living · Updated: 2026-06-10

A claim asserts "agent X is working goal Y until ts+ttl". Claims live **only** on the unprotected `claims` branch (ADR-004); they never appear on `main`.

## File format

`claims/<goal-id>.<agent-id>.aisp` — exactly two dots in the filename (ids contain no dots).

```
𝔸5.1.claim.<goal-id>.<agent-id>@YYYY-MM-DD
γ≔unsorry.claim
⟦Ω:Claim⟧{goal≜<goal-id>; agent≜<agent-id>}
⟦Σ:Times⟧{ts≜2026-06-10T03:12:45Z; ttl≜7200}
⟦Γ:Expiry⟧{now>ts+ttl⇒expired}
⟦Λ:Release⟧{release≜λ_.rm(self)}
⟦Ε⟧⟨δ≜0.60;τ≜◊⁺⟩
```

## Field rules

| Field | Domain | Rules |
|---|---|---|
| `goal` | `Id` | Must equal filename field 1; should reference an existing goal (checked when `--goals-root` is supplied) |
| `agent` | `Id` | Must equal filename field 2 |
| `ts` | ISO-8601 UTC with `Z` suffix | Claim creation time, set by the claiming agent |
| `ttl` | integer seconds | Default 7200; bounds `600 ≤ ttl ≤ 86400`; must be ≥ 4× the reaper interval (SPEC-004-A) |

## Liveness and cardinality

- A claim is **live** iff `now ≤ ts + ttl`; otherwise **expired** (reapable).
- Per goal, live claims are bounded by phase: `translate` ≤ 2 live claims by **distinct** agents (the dual-translation gate needs two independent workers, and an agent must not claim a goal it already translated); `prove` ≤ 1.
- Without `--goals-root` (claims tree alone), the validator enforces the weaker bound ≤ 2 plus agent distinctness.

## Gate B checks

| Code | Check |
|---|---|
| GB010 | Filename grammar: `<Id>.<Id>.aisp`, exactly two dots |
| GB011 | Header/body schema: header name `claim.<goal>.<agent>` matches fields; `ts` parses as ISO-8601 UTC `Z` |
| GB012 | `ttl` within bounds |
| GB013 | Claim expired at validation time (`--at` injects the clock for tests; reaper consumes this signal) |
| GB014 | Live-claim cardinality per goal within phase cap |
| GB015 | No two live claims on one goal by the same agent |

GB013 is a *freshness report*, not necessarily a PR-blocking failure on the claims branch — the reaper (SPEC-004-A) is the remover. On `main`, any file under `claims/` other than `claims/README.md` is itself a violation (claims do not live on main).

## Acceptance criteria (PR-3 tests)

1. `claims_valid/` fixture passes with injected clock `--at 2026-06-10T01:00:00Z`.
2. Same fixture reports GB013 for both claims with `--at 2026-06-10T03:00:01Z` (ts 2026-06-10T00:00:00Z + ttl 7200 < now).
3. `invalid_claim_*` and `invalid_triple_claim` fixtures fail with their named codes.
4. Determinism: two runs with the same `--at` produce byte-identical reports.
