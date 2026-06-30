# SPEC-114-A: Rebase-First Recovery When a Flaked-Gate PR Is Behind Its Base

Implements: [ADR-114](../ADR-114-Rebase-First-Recovery-For-Base-Stale-Flaked-Gates.md) · Status: Living · Updated: 2026-06-30

ADR-114 makes the ADR-112 flaked-gate retry **branch-state aware**: when a
`BLOCKED` candidate's branch is behind its base, recover it by **rebasing**
(`update-branch`) instead of re-running the same stale head SHA — a rerun cannot
clear a base-staleness failure (the canonical case is a cold-cache
`gate_a_prepare` that times out because its published-olean cache key is
superseded). This spec is the contract; it amends SPEC-112-A §3 (the shell).

## 1. Deliverables

| # | Deliverable | Surface | CODEOWNERS? |
|---|---|---|---|
| D1 | `recovery_action(behind_by, no_rebase) -> {"rebase","rerun"}` pure function | `tools/repo/flaky_gate_retry.py` | no |
| D2 | Shell: read `baseRefName`; compute `behind_by` once per confirmed candidate; act loop dispatches on `recovery_action` | same | no |
| D3 | Tests for `recovery_action` (behind/up-to-date × rebase-enabled/disabled) | `tools/repo/tests/test_flaky_gate_retry.py` | no |
| D4 | ADR-114 + this spec + changelog fragment | `docs/adrs/**`, `changelog.d/` | no |

No `.github/` change: the workflow already passes `--no-rebase` when
`REFRESH_TOKEN` is absent, and `recovery_action` honours it, so the whole change
lives in non-CODEOWNERS paths.

## 2. Pure function (D1)

`recovery_action(behind_by: int, no_rebase: bool) -> str`:

- returns `"rebase"` **iff** `behind_by > 0 and not no_rebase`;
- returns `"rerun"` otherwise (up to date — an `update-branch` would be a no-op;
  or `no_rebase` — no token, cannot synchronize).

Pure, side-effect-free, exhaustively unit-tested. It is the single decision point;
the shell only executes the chosen action.

## 3. Shell (D2) — amends SPEC-112-A §3

- The open-PR query adds `baseRefName` to the `--json` field set.
- For each **confirmed** retry candidate (after `flaky_retry_reason` passes), read
  `behind_by = _behind_by(repo, baseRefName or "main", headRefOid)` — the helper
  imported from `dropped_gate_prs` (a single `compare/{base}...{sha}` call, so
  bounded by `--limit`; not called for non-candidates) — and carry it on the
  candidate tuple.
- The act loop computes `action = recovery_action(behind_by, args.no_rebase)`:
  - **`"rebase"`** → `update-branch`. On success: count `rebased`, report
    `behind base by N — rerun would reproduce a stale-base failure`. On failure
    (conflict / lost an up-to-date race): log to stderr and **fall through** to the
    rerun path — never leave the candidate unrecovered when a rerun is still
    available.
  - **`"rerun"`** → the unchanged SPEC-112-A path: `gh run rerun <run-id>
    --failed`; if GitHub rejects it (stale run), fall back to `update-branch`.
- Dry-run prints `would <action> #N …` with `(behind base by N)` when `behind > 0`,
  so a `--apply`-less run shows which PRs would rebase vs rerun.
- Counts (`retried`, `rebased`) and the `exhausted` (`--max-attempts` reached →
  left BLOCKED for a human) report are unchanged; nothing is silently dropped.
- Defaults unchanged: `--required gate-a`, `--max-attempts 3`,
  `--min-age-minutes 15`, `--limit 20`, dry-run unless `--apply`, rebase paths on
  unless `--no-rebase`.

## 4. Invariants

- **No regression without a token.** With `--no-rebase`, `recovery_action` always
  returns `"rerun"`, so behaviour is byte-identical to pre-ADR-114 (a base-stale PR
  reruns to `--max-attempts` then is surfaced).
- **Bounded.** `recovery_action` does not touch the attempt cap; a real failure
  still converges to a visible block. A rebase changes the head SHA, starting a
  fresh `run_attempt` sequence on a *different* base — by design, since the cause
  (the stale base) is gone.
- **Soundness untouched.** Both actions re-run the real gates (ADR-049, p=1); no
  gate is bypassed and no proof trusts another.
- **DRY.** `behind_by` reuses `dropped_gate_prs._behind_by`; `PENDING_STATES` /
  `TERMINAL_NONPASS` / `normalize_run_state` remain shared with the dropped-gate
  janitor.

## 5. Tests (D3)

`recovery_action`: `(2, no_rebase=False) → "rebase"`; `(0, False) → "rerun"`;
`(5, no_rebase=True) → "rerun"`; `(0, True) → "rerun"`. The existing
`flaky_retry_reason` / `run_id_from_details_url` suites are unchanged and continue
to pass (14 + 4 = 18 cases).
