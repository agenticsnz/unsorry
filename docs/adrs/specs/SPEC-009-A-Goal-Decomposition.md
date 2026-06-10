# SPEC-009-A: Goal Decomposition

Implements: [ADR-009](../ADR-009-Goal-Decomposition.md) · Refines: [SPEC-003-C](SPEC-003-C-Translation-and-Decomposition-Records.md), [SPEC-007-A](SPEC-007-A-Agent-Loop-Script.md) · Status: Living · Updated: 2026-06-10

Puts the SPEC-003-C decomposition record into the prove cycle at the slot SPEC-007-A step 11 deferred. Soundness is unchanged: a parent only ever closes through Gate A using its sub-lemmas; the dependency edges are advisory routing hints, never a trust path.

## Trigger and fallback

When a prove attempt exhausts its budget (`run_proof` fails across `config.BUDGET_ATTEMPTS`), the agent attempts **decomposition** (`decompose_goal`) before the affinity demote. Decomposition is on by default; `UNSORRY_DECOMPOSE=0` reverts to the Phase-1 demote-only path (ADR-010). If decomposition is not possible — the depth cap is hit, `claude` produced fewer than 2 usable subs, the subs do not type-check, or a guardrail rejects the split — the agent falls back to the `−10` affinity demote (SPEC-010-A), so a non-decomposable failure is at least deprioritised.

## Decomposition (`decompose_goal`)

1. **Depth gate.** Read the parent's advisory `depth` field (`goal-depth`, absent ⇒ 0). If `depth ≥ config.MAX_DECOMP_DEPTH` (= 3), decline (fall back to demote). Each sub is rendered at `depth + 1`, so the chain terminates.
2. **Propose subs.** Drive `claude` (`swarm/prompts/decompose.md` + the parent's Lean statement) to emit 2–`config.MAX_DECOMP_SUBS` (= 8) `SUB:` lines, each a complete Lean theorem signature with no proof. Non-`SUB:` lines are ignored. The call is read-only (`Read`, read-only `lake`); it writes no files.
3. **Materialise and guard.** Each sub becomes `goals/<parent>-s<i>.lean` = `import Mathlib` + the signature + `:= by sorry`, and `goals/<parent>-s<i>.aisp` (`render-goal`: phase prove, status open, `src` = the decomposition record, `depth` = parent + 1). Guardrails: a sub whose normalized Lean statement equals the parent's is dropped (**strictly-smaller**); excess subs past the cap are dropped. Fewer than 2 surviving subs ⇒ decline.
4. **Record and block.** Write `decompositions/<parent>.<agent>.aisp` (`render-decomp`: one `Post(sub_i) ⊆ Pre(parent)` edge per sub — every sub is a prerequisite of the parent, a DAG) and flip the parent to `status≜blocked` (`rewrite-goal`).
5. **Type-check.** `lake build UnsorryGoals` in the worktree (cache restored with `lake exe cache get`) — a split that does not even parse is worthless and declines.
6. **Commit.** A gated PR carrying `goals/` (new subs + blocked parent) and `decompositions/`. Emits a `decomposed` event.

## Unblock sweep (`unblock_sweep`)

A prove-mode cycle step (the prove analogue of the translate convergence sweep). `py_helper unblockable goals decompositions library` lists every `blocked` parent whose decomposition's sub ids are **all** in the proved set (each named by a `library/index/<sha>.aisp`). For each (once per session, tracked in `SWEPT`), a small gated PR flips the parent back to `status≜open`. The agent then claims the parent normally and proves its own signature with the subs available as library imports — closing only through Gate A.

## Gate B guardrails (ADR-009, added to `_validate_decomposition`)

Beyond the SPEC-003-C structural checks (header, parent/sub identity, 1–8 subs, edge endpoints), Gate B now also enforces (all GB016):

- **Strictly-smaller:** a sub id equal to the parent id is rejected (`sub re-emits the parent goal`).
- **Acyclicity:** the `Post(A) ⊆ Pre(B)` edge set (edge `A → B`) must be a DAG; a dependency cycle is rejected (`_has_cycle`).

Depth is an advisory `depth` field (like `aff`): Gate B does not enforce it; the agent enforces the cap at decompose time.

## Constants

`config.MAX_DECOMP_SUBS` (8), `config.MAX_DECOMP_DEPTH` (3); `py_helper max-decomp subs|depth` exposes them so the shell never hardcodes them. `MAX_DECOMP_SUBS` in the validator now references `config`.

## Acceptance criteria (`--self-test`, hermetic + Gate B)

1. `test_decomp_caps_and_depth` — `max-decomp` matches config; `render-goal`/`goal-depth` round-trip the depth field; absent ⇒ 0.
2. `test_unblockable_detection` — a blocked parent is unblockable iff *all* its decomposition subs are proved.
3. `test_render_decomp_gateb` — a rendered decomposition record + sub goal records validate under the real Gate B.
4. `test_has_cycle_unit`, `test_decomposition_cycle_is_rejected`, `test_decomposition_sub_re_emitting_parent_is_rejected` (Gate B suite) — the acyclicity and strictly-smaller guardrails.

The claude-driven proposal step (like the prove cycle's `run_proof`) is exercised live in the Stage-E Phase-2 run, not in `--self-test`.
