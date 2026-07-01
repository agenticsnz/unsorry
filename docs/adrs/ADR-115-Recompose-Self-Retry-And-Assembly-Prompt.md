# ADR-115: Recompose Self-Retry and Assembly Prompt Hardening

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-115 |
| **Initiative** | unsorry swarm reliability — auto-recompose closure |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-07-01 |
| **Status** | Accepted |

## Context

ADR-009's unblock→recompose sweep re-opens a fully-proved-subtree parent for **recomposition** —
a prove attempt that assembles the proved sub-lemmas (surfaced as importable modules by ADR-014
`proved-deps`) into the parent. ADR-034 floors a *failed* recompose demote at `TAU_V` instead of
burying it, explicitly "so the parent sinks to lowest-but-viable priority and the sweep keeps
auto-retrying it."

That retry never happens inside the process that failed the recompose. The main prove loop tracks
a per-session `HANDLED` set and every candidate selector (`select_prove_candidates`,
`select_recovery_candidates`) drops goals in it, to avoid thrashing one goal in a single session.
So after one failed recompose the parent is removed from **every** pool for the life of the
process: `prove-candidates` skips it (HANDLED), and `recovery-candidates` ignores it too (it keeps
only `affinity < TAU_V`, but a floored recompose sits *at* `TAU_V`, viable). A long-running
`./swarm/run.sh --prove --goal <parent>` therefore attempts the assembly exactly once, floors it,
then logs "no viable or recoverable prove work this pass" every cycle and idles forever — the
proved subtree never closes without a manual restart, and a restart only re-gambles the *same*
one-shot attempt.

The observed case: `aime-1983-p9` decomposed into three sub-lemmas, all proved and merged; the
recompose then failed a single high-effort attempt on what is a four-line glue (instantiate the
divided-AM-GM sub-lemma at `y = x·sin x`, `ring`-reconcile `x²·sin²x = (x·sin x)²`, close with the
positivity sub-lemma). ADR-014 correctly surfaced all three lemmas to the model; it simply did not
assemble them, and the loop then parked the goal.

## WH(Y) Decision Statement

**In the context of** ADR-034's recompose demote that floors a failed assembly at `TAU_V` so it
"stays viable for the sweep to retry," and the per-session `HANDLED` dedup that removes a goal from
both the viable and recovery pools after one attempt,
**facing** the fact that the retry ADR-034 promises never fires inside the process that failed the
recompose — HANDLED blocks re-selection and the `TAU_V`-floored goal is too *viable* for the ADR-044
recovery pool — so a long-running `--prove --goal <parent>` idles at "no viable or recoverable prove
work" forever and a manual restart only re-runs the same single attempt (observed: `aime-1983-p9`, a
four-line glue the model missed although ADR-014 surfaced every sub-lemma),
**we decided for** two mechanisms: (1) **bounded in-session self-retry** — on an otherwise-idle
prove pass, re-arm one in-scope recompose-candidate this session already tried (clear it from
`HANDLED`), capped per goal by `UNSORRY_RECOMPOSE_RETRIES` (default 2), so the loop retries the
assembly up the ADR-015 effort ladder instead of parking; and (2) **assembly prompt hardening** — a
recompose-specific prompt block that tells the model the surfaced (ADR-014) sub-lemmas are
*sufficient* and to assemble them (instantiate, `ring`-normalize, close) rather than prove from
scratch,
**and neglected** clearing `HANDLED` unconditionally for recompose-candidates (unbounded thrash on a
truly-unprovable assembly), operator-restart-only recovery (defeats an *automatic* sweep and only
re-gambles the same attempt), and deterministic tactic synthesis of the glue (does not generalise —
the winning glue needs a problem-specific `ring` rewrite),
**to achieve** automatic closure of a fully-proved subtree within a single run and a materially
higher recompose success rate,
**accepting that** a genuinely unprovable recompose still spends up to `UNSORRY_RECOMPOSE_RETRIES`
attempts per session before idling (bounded, and a fresh process re-arms once more), that the prompt
block is advisory and never gates a proof, and that both mechanisms are env-gated default-on so the
prior behaviour is one variable away (`UNSORRY_RECOMPOSE_RETRIES=0`).

## Options Considered

### Option 1: Bounded self-retry + assembly prompt hardening (Selected)
Re-arm a HANDLED recompose-candidate up to `UNSORRY_RECOMPOSE_RETRIES` times per session, and steer
the model to assemble the surfaced sub-lemmas. **Pros:** realises ADR-034's intended retry within a
single run; escalates effort (ADR-015) across retries; attacks the actual failure (a missed trivial
assembly). **Cons:** a permanently-unprovable recompose burns up to the cap before idling.

### Option 2: Prompt hardening only (Rejected)
Keep the loop behaviour; only improve the prompt. **Rejected:** a model that needs the *escalated*
rung (xhigh/max) never gets a second in-session try — the loop still idles after the first attempt,
so `run.sh --prove --goal <parent>` still requires manual restarts to make progress.

### Option 3: Unconditional HANDLED clear for recompose-candidates (Rejected)
Never add a recompose-candidate to `HANDLED`. **Rejected:** an assembly the model genuinely cannot
close is retried every pass with no bound — a budget-poisoning loop, the exact failure mode ADR-034
guarded against by ranking, reintroduced.

### Option 4: Deterministic glue synthesis (Rejected)
Auto-generate the assembly from the decomposition edges. **Rejected:** does not generalise — the
observed glue required a problem-specific `ring` rewrite; a template `exact`-of-subs covers only the
trivial cases and would still leave the general recompose to the model.

## Dependencies
| Relationship | ADR ID | Title | Notes |
|--------------|--------|-------|-------|
| Refines | ADR-034 | Recompose Failure Must Not Bury a Proved Subtree | Adds the in-session retry the τ_v floor was meant to enable |
| Refines | ADR-009 | Goal Decomposition | Makes the unblock→recompose sweep self-closing within a run |
| Relates To | ADR-044 | Idle Recovery of Parked Goals | Sibling: recovery re-surfaces goals *below* τ_v; this re-arms recompose-candidates *at* τ_v |
| Relates To | ADR-015 | Effort Ladder | Retries climb high→xhigh→max as fresh attempts |
| Relates To | ADR-014 | Dependency Reuse | The prompt block references the sub-lemmas ADR-014 already surfaces |

## References
| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Recompose self-retry spec | Specification | specs/SPEC-115-A-Recompose-Self-Retry-And-Assembly-Prompt.md |
| REF-2 | Recompose no-bury (the floor this retries against) | ADR | ADR-034-Recompose-Failure-No-Bury.md |
| REF-3 | Recompose tracking issue | Issue | <https://github.com/agenticsnz/unsorry/issues/388> |

## Status History
| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-07-01 |
| Accepted | unsorry maintainers | 2026-07-01 |
