# SPEC-059-A: Fetch Resilience on the Shared Object Store

Implements: [ADR-059](../ADR-059-Fetch-Resilience-On-Shared-Object-Store.md) · Status: Living · Updated: 2026-06-16

## Backoff schedule (pure)

`fetch_retry_delay <attempt> <base> <cap>` (swarm/agent.sh) is a pure function
printing the seconds to sleep **before** the next attempt:

- `delay = base * 2^(attempt-1)`, with the shift clamped at 6 (`base*64`) to
  bound the arithmetic, then capped at `cap`.
- `attempt` is the 1-based index of the *just-failed* attempt; `base = 0` yields
  `0` for every attempt (the self-test uses this to avoid real sleeps).

## Retry wrapper

`git_fetch_retry <dir> <fetch-args…>` runs `git -C <dir> -c gc.auto=0 fetch <fetch-args…>`:

- `-c gc.auto=0` keeps a concurrent `gc`/repack from pruning objects underneath
  the fetch (the #983 race window).
- `<dir>` is the repo to fetch into (`.` for the current worktree, `$CLAIMS_WT`
  for the claims worktree) — a single helper covers every site.
- On success → `return 0`.
- On failure, if attempts remain (`< UNSORRY_FETCH_RETRIES`, default 3): log the
  attempt, `sleep "$(fetch_retry_delay …)"` (base `UNSORRY_FETCH_BACKOFF`,
  default 2; cap 30), retry.
- On the final failure: log the exhausted attempt count and **`return 3`** (the
  ADR-016 infrastructure code).

`UNSORRY_FETCH_RETRIES` (default 3) and `UNSORRY_FETCH_BACKOFF` (default 2) are
env-overridable integers, documented in `--help` — like the existing
`UNSORRY_WALL` / `UNSORRY_FASTFAIL` operational knobs, they are consumed
directly rather than pre-validated.

## Propagation

Code 3 = infrastructure failure, threaded through the fetch sites:

- `sync_repo`: `git_fetch_retry . -q origin || return $?` — the exhausted-fetch
  3 propagates; a `reset`/`merge --ff-only` failure still returns 1, and
  `require_main_matches_origin` still `die_config`s (2).
- `ensure_claims_worktree` (called only by `sync_repo`): the claims fetch goes
  through `git_fetch_retry "$CLAIMS_WT" -q origin claims || return $?`, so its
  exhaustion also surfaces as 3 up through `sync_repo`.
- main loop: `sync_repo || { rc=$?; log "repository sync failed"; exit "$rc"; }`
  — exit 3 on exhausted fetch (→ `supervise.sh` exponential infra backoff,
  ADR-017), exit 1 on the other sync failures (→ 120 s cycle retry).
- `relocate_into_agent_worktree` (pre-loop startup):
  `git_fetch_retry . -q origin || die_infra "…"` (`die_infra` exits 3, mirroring
  `die_config`) — a transient startup fetch failure is no longer a fatal
  config error.

No raw `git fetch origin` remains in the loop or startup paths.

## Acceptance criteria

`test_fetch_retry_delay` (agent.sh self-test, pure):

1. `fetch_retry_delay 1 2 30` → `2`;
2. `fetch_retry_delay 2 2 30` → `4`;
3. `fetch_retry_delay 3 2 30` → `8`;
4. `fetch_retry_delay 9 2 30` → `30` (capped);
5. `fetch_retry_delay 1 0 30` → `0` (zero base never sleeps).

`test_git_fetch_retry` (agent.sh self-test, hermetic — bare `file://` origin, no
network, `UNSORRY_FETCH_BACKOFF=0`):

1. a fetch against a healthy origin returns 0;
2. a fetch against a non-existent remote returns **3** after
   `UNSORRY_FETCH_RETRIES` attempts;
3. the exhaustion path logs the attempt count and exactly
   `UNSORRY_FETCH_RETRIES - 1` inter-attempt retry lines (it really looped).

Shellcheck-clean. Incident record: issue #983 — post-fix, a transient
shared-store fetch race must be survived by retry, and a durable fetch outage
must surface as exit 3 (supervisor backoff), never exit 1 or a halted run.
