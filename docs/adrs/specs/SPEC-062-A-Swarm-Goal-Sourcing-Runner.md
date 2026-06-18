# SPEC-062-A: Swarm Goal-Sourcing Runner

Implements: [ADR-062](../ADR-062-Swarm-Goal-Sourcing-Runner.md) · Status: Living · Updated: 2026-06-17

One deliverable: `swarm/sourcing.sh`, a harness that fires up Claude to run the
`unsorry-goal-sourcing` skill (ADR-060 / SPEC-060-A) one cycle at a time, plus
the `swarm/prompts/source.md` playbook it injects. It is the sourcing counterpart
to `swarm/agent.sh` (SPEC-007-A) and reuses that script's conventions verbatim.
This spec is the contract for the script's CLI, behaviour, and quality bar.

## 1. CLI surface

```
./swarm/sourcing.sh [--once] [--theme <name>] [--max-goals <N>] [--dry-run]
./swarm/sourcing.sh --cycles <N> [--theme <name>] [--max-goals <N>]
./swarm/sourcing.sh --self-test
```

| Flag | Meaning |
|---|---|
| `--once` | Run exactly one cycle then exit (also the default). Forces the cycle count to 1, overriding `--cycles`/`UNSORRY_SOURCING_CYCLES`. |
| `--cycles <N>` | Run N cycles (one theme/PR each), sleeping `UNSORRY_SOURCING_INTERVAL` between them. Must be a positive integer. |
| `--theme <name>` | Force the theme for every cycle. Default: the prompt instructs Claude to choose one hard family itself. |
| `--max-goals <N>` | Hard cap on new goals per cycle/PR; clamped to `[1, 50]` (SPEC-060-A PR discipline). Non-integer/empty → 50. |
| `--dry-run` | Assemble and print the prompt, then exit 0 — no network preflight, no Claude call, no PR. |
| `--provider <p>` | Only `claude` is supported; anything else is a config error (exit 2). |
| `--self-test` | Run the built-in hermetic tests and exit (0 green / 1 red). |
| `-h`, `--help` | Print usage and exit 0. |

## 2. Cycle behaviour (one cycle = one Claude call)

1. **Snapshot.** `goal_slugs goals` lists every `goals/<slug>.aisp` basename,
   sorted and unique — the dedup set handed to Claude.
2. **Prompt.** `build_prompt <theme> <max_goals> <solver> <snapshot>` emits
   `source.md` followed by a `RUNTIME PARAMETERS` block carrying the theme (or
   the "choose one yourself" instruction), the `≤max_goals` cap, the solver
   handle to credit, and the snapshot. Pure in its arguments (hermetically
   testable).
3. **Call.** `timeout "$UNSORRY_WALL" claude -p "$prompt" --model "$(resolve_model)"
   [--effort "$UNSORRY_EFFORT"] --output-format text --allowedTools <scope>`.
   `resolve_model` defaults to `opus` (sourcing is reasoning/tool-heavy),
   overridable via `UNSORRY_MODEL`; a `fable` request that is unavailable falls
   back to `opus`, mirroring `agent.sh`.
4. **Classify.** On a non-zero Claude exit, run the ADR-016 health probe and
   `classify_call_failure <dur> <fastfail> <probe_rc>`: a fast failure
   (`dur < UNSORRY_FASTFAIL`) with a dead probe is **infrastructure** →
   `die_infra` (exit 3, no penalty); anything else is a **cycle failure**
   (return 1). A clean exit returns 0.

`--allowedTools` is scoped to the sourcing toolchain and the single PR; it
deliberately excludes `library/`, the lakefiles, the gates, and the harness:

```
Read, Edit, Write,
Bash(python3 -m tools.sourcing.*), Bash(python3 -m tools.gate_b *),
Bash(lake build UnsorryGoals*), Bash(lake env *), Bash(lake exe *),
Bash(git fetch *|checkout *|switch *|add *|commit *|push *|diff *|status*|rev-parse *|log *|branch *|restore *),
Bash(gh pr *), Bash(gh api *), Bash(gh auth status*)
```

## 3. Bounded loop (ADR-062)

`resolve_cycles` returns 1 when `--once` is set, else `--cycles` /
`UNSORRY_SOURCING_CYCLES` / 1. The loop runs that many cycles; between cycles it
`git_fetch_retry . origin main`, fast-forwards `main`, and sleeps
`UNSORRY_SOURCING_INTERVAL` (default 60s). There is **no** loop-until-empty
default: sourcing has no empty-pool fixed point, so an unbounded loop is never
the default (ADR-062).

## 4. Preflight (skipped under `--dry-run`)

`require_repo_root` (always); then for a live run: `require_cmd claude gh`,
`require_unsorry_origin`, `require_main_checkout`, `gh auth status`,
`git_fetch_retry . origin main` (ADR-059 retrying fetch; propagates exit 3),
`require_main_matches_origin`, and the ADR-016 `cli_health_probe`
(`die_infra` if Claude is not callable). `UNSORRY_WALL`/`UNSORRY_FASTFAIL` must be
integers.

## 5. Exit codes (supervise-compatible)

| Code | Meaning |
|---|---|
| 0 | Success, or nothing to do (incl. every `--dry-run`). |
| 1 | A cycle failed (a real, non-infrastructure Claude failure). |
| 2 | Configuration error — not at repo root, missing tool, unauthenticated `gh`, bad flag/knob, unsupported provider. |
| 3 | Infrastructure failure — Claude CLI uncallable (ADR-016) or a shared-object-store fetch exhausted its retries (ADR-059). |

These match `agent.sh` exactly, so `swarm/supervise.sh`'s `next_action` policy
(backoff on 3, short retry on 1, fatal on 2) wraps `sourcing.sh` unchanged.

## 6. Environment

| Variable | Default | Purpose |
|---|---|---|
| `UNSORRY_MODEL` | `opus` | Claude model for the cycle. |
| `UNSORRY_EFFORT` | (unset) | Optional `--effort` forwarded to Claude. |
| `UNSORRY_WALL` | `2400` | Wall-clock seconds per Claude call. |
| `UNSORRY_FASTFAIL` | `240` | Below this, a failed call is suspected infrastructure (ADR-016). |
| `UNSORRY_MAX_GOALS` | `50` | Default `--max-goals`. |
| `UNSORRY_SOURCING_CYCLES` | `1` | Default cycle count. |
| `UNSORRY_SOURCING_INTERVAL` | `60` | Sleep seconds between cycles. |
| `UNSORRY_SOLVER` | `gh api user` | Leaderboard handle credited for sourced goals. |
| `UNSORRY_FETCH_RETRIES`, `UNSORRY_FETCH_BACKOFF` | `3`, `2` | ADR-059 fetch-resilience knobs. |

## 7. Quality bar (SPEC-007-A, enforced by `agent-lint.yml`)

`swarm/sourcing.sh` is added to the `agent-lint` workflow next to
`agent.sh`/`supervise.sh`:

- `shellcheck swarm/sourcing.sh` — clean at default severity (no findings).
- `bash -n swarm/sourcing.sh` — clean.
- `./swarm/sourcing.sh --self-test` — green. The tests are **hermetic** (temp
  dirs, in-process arg/prompt assertions; no network, no Claude, no repo
  mutation) and cover: `clamp_max_goals` range/fallback, `resolve_model`
  default+override, `resolve_cycles` (`--once`/`--cycles`/default), `goal_slugs`,
  `build_prompt` (theme/cap/solver/snapshot/skill-ref present, and the
  model-choice branch), `fetch_retry_delay` (ADR-059 schedule),
  `classify_call_failure` (ADR-016), `parse_args`, and `usage`.

## 8. Out of scope (deferred)

- A shared `swarm/lib.sh` to de-duplicate the pure helpers (`fetch_retry_delay`,
  `classify_call_failure`, `cli_health_probe`) shared with `agent.sh` — its own
  ADR (refactoring the 5k-line prove runner is a CODEOWNERS-owned change).
- Non-Claude providers for sourcing.
- The harness owning the branch/commit/PR plumbing (Claude owns it in-cycle under
  the scoped allowlist for the MVP).
- Fork/at-scale rollout, which waits on ADR-054 quota/abuse controls.
