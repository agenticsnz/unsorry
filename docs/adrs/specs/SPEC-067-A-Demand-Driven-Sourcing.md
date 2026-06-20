# SPEC-067-A: Demand-Driven Sourcing

Implements: [ADR-067](../ADR-067-Demand-Driven-Sourcing.md) · Status: Living · Updated: 2026-06-17

One deliverable: a new opt-in `--if-pool-empty` flag on `swarm/sourcing.sh`
(SPEC-062-A) that makes the sourcing runner **demand-driven** — it sources only
when there are no problems left to solve, and otherwise no-ops. No new files;
this extends the existing runner and its hermetic self-test. This spec is the
contract for the flag's CLI, behaviour, and quality bar; everything not restated
here is unchanged from SPEC-062-A.

## 1. CLI surface (delta from SPEC-062-A §1)

```
./swarm/sourcing.sh --if-pool-empty [--cycles <N>] [--theme <name>] [--max-goals <N>] [--dry-run]
```

| Flag | Meaning |
|---|---|
| `--if-pool-empty` | Demand-driven gate. Before each cycle, source **only if** the prove pool is empty (zero `goals/<slug>.aisp` carry `status≜open`); otherwise stop the loop with exit 0 — no Claude call, no PR. Default **off** (every existing invocation is unchanged). Composes with `--cycles`, `--theme`, `--max-goals`, `--dry-run`. |

## 2. "Problems to solve" — `open_goal_count`

```
open_goal_count <goals-dir>   # default: goals
```

Prints the count of goal records that still represent unsolved work: every
`<goals-dir>/*.aisp` whose text contains a `status≜open` field line. Properties:

- **Authoritative marker.** It reads the same `status≜` field that
  `swarm/supervise.sh:scope_closed` reads. A merged proof rewrites
  `status≜open` → `status≜proved` (SPEC-007-A step 8), so an `open` goal is
  exactly an unsolved one. `status≜proved` and `status≜blocked` records are **not**
  counted (proved = done; blocked = parked on its sub-lemmas, which are
  themselves `open` and counted). DRY: no second "proved" computation, no library
  index read, no claim awareness.
- **Pure.** A function of its directory argument only — no network, no Claude, no
  repo mutation — so it is hermetically testable. A missing directory prints `0`.
- **Non-`.aisp` ignored;** the `for f in "$dir"/*.aisp` loop guards each entry
  with `[ -e "$f" ]` so an empty match is `0`, not a literal-glob error.

## 3. Gate placement and loop behaviour

The gate lives at the **top of the cycle loop** in `main`, after the preflight
(SPEC-062-A §4) has synced `main` to `origin/main`:

```
for (( i = 1; i <= cycles; i++ )); do
  if [ "$IF_POOL_EMPTY" -eq 1 ]; then
    open_n="$(open_goal_count goals)"
    if [ "$open_n" -gt 0 ]; then
      log "--if-pool-empty: $open_n open goal(s) still to solve — skipping sourcing (no PR)"
      break                       # exit 0 (overall stays 0); nothing-to-do
    fi
    log "--if-pool-empty: prove pool empty — sourcing to replenish the backlog"
  fi
  ...run_cycle...
done
```

- **Per-cycle re-check.** Because the gate runs each iteration, and SPEC-062-A
  already `git_fetch_retry`s + fast-forwards `main` between cycles, a multi-cycle
  run gates the first cycle **and** stops the instant the backlog refills (a prior
  cycle's PR merged, or a prover queued new work). The first cycle being gated is
  the single-cycle (default / `--once`) case.
- **Empty ⇒ source.** Zero open goals → fall through to the normal bounded
  `run_cycle` (one theme, one `chore(sourcing):` PR), exactly as ADR-062.
- **Non-empty ⇒ no-op.** `break` with `overall` still `0`, so the script exits
  **0** ("nothing to do") having made no Claude call and no PR.
- **Snapshot semantics.** The gate reads the working-tree `goals/`: synced to
  `origin/main` by the live-run preflight fetch; the local tree under `--dry-run`
  (which makes no network call). A sourcing PR opened this cycle but not yet
  merged is not counted as backlog until it lands — the operator re-invokes and
  the next tick sees it.

## 4. Interaction with other flags

| Combination | Behaviour |
|---|---|
| `--if-pool-empty` alone | One cycle: source iff the pool is empty. |
| `--if-pool-empty --cycles N` | Up to N cycles, each gated; stops early once the pool is non-empty. |
| `--if-pool-empty --dry-run` | Gate evaluated against the local `goals/`; if empty, prints the assembled prompt (no call/PR); if non-empty, logs the skip and exits 0 without printing a prompt. |
| `--if-pool-empty --theme/--max-goals` | Unchanged; these parameterise the cycle that runs when the gate opens. |

## 5. Exit codes (unchanged from SPEC-062-A §5)

`0` ok / nothing-to-do (incl. the gated no-op) · `1` cycle fail · `2` config ·
`3` infra. `supervise.sh`'s `next_action` policy wraps `sourcing.sh` unchanged.

## 6. Quality bar (SPEC-007-A, enforced by `agent-lint.yml`)

No workflow change — `sourcing.sh` is already in `agent-lint`. The bar is the
same and must stay green:

- `shellcheck swarm/sourcing.sh` — clean at default severity.
- `bash -n swarm/sourcing.sh` — clean.
- `./swarm/sourcing.sh --self-test` — green. Hermetic tests gain:
  - **`test_open_goal_count`** — a temp dir with two `status≜open`, one
    `status≜proved`, one `status≜blocked`, and one non-`.aisp` file counts `2`;
    flipping the two open records to `proved` counts `0`; a removed dir counts
    `0`.
  - **`test_parse_args`** — extended to assert `--if-pool-empty` sets
    `IF_POOL_EMPTY=1` and that it defaults to `0`.
  - **`test_usage_smoke`** — extended to assert `--if-pool-empty` appears in
    `usage`.

## 7. Out of scope (deferred)

- The prove → source **bridge** in `supervise.sh` / `agent.sh` (have the prover
  invoke `sourcing.sh --if-pool-empty` when its own pool is empty). ADR-067
  delivers the mechanism; wiring it into the prove arm is a separate change to a
  CODEOWNERS-owned policy surface (ADR-017).
- Claim-aware or viability-weighted pool definitions (the gate counts open goals
  tree-wide, matching `scope_closed`).
- Counting in-flight (unmerged) sourcing PRs toward the backlog.
- A shared `swarm/lib.sh` to de-duplicate the `status≜` read with `supervise.sh`
  (inherits SPEC-062-A §8's deferral).
