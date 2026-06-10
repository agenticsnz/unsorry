# SPEC-007-A: Agent Loop Script (`swarm/agent.sh`)

Implements: [ADR-007](../ADR-007-Agent-Identity-and-Budgets.md) · Status: Living · Updated: 2026-06-10

Phase-0 scope: **translation-only mode**. The prove cycle extends this spec in Phase 1 (same skeleton, extra `work`/`verify` arms).

## Invocation

```
./swarm/agent.sh --translate-only [--once] [--goal <id>] [--dry-run]
./swarm/agent.sh --self-test
```

| Flag | Meaning |
|---|---|
| `--translate-only` | Phase-0 mode: only `phase ≡ translate` goals are candidates (required for now; the flag exists so Phase 1 can add the default full mode) |
| `--once` | Run exactly one cycle then exit (default: loop until no claimable goal or budget spent) |
| `--goal <id>` | Restrict selection to one goal (trial orchestration) |
| `--dry-run` | Stop after selection: print the goal that would be claimed, claim nothing |
| `--self-test` | Run the built-in pure-function tests and exit (0 green / 1 red) |

Must be run from the repository root (script verifies `swarm/protocol.aisp` exists and the `origin` remote points at an unsorry repo).

## Environment

| Var | Default | Meaning |
|---|---|---|
| `UNSORRY_AGENT_ID` | contents of `~/.unsorry/agent-id` (created on first run: `<short-hostname>-<4 hex>`) | Swarm identity (ADR-007) |
| `UNSORRY_MODEL` | `sonnet` | Model for translation calls |
| `UNSORRY_WORKDIR` | `~/.unsorry/work` | Holds the claims-branch worktree and `metrics.jsonl` |
| `UNSORRY_WALL` | `1800` | Wall-clock seconds per cycle (`timeout` around the claude call) |
| `UNSORRY_TTL` | read from `tools/gate_b/config.py` (7200) | Claim TTL; the script reads the config value — never hardcodes it (DRY with the contract) |

Authentication: whatever `claude` auth exists (subscription login or `ANTHROPIC_API_KEY`); `gh` must be authenticated for PR creation.

## Cycle (translate-only)

1. **Pull** `main`; ensure the claims worktree exists (`git worktree add "$UNSORRY_WORKDIR/claims-branch" claims` tracking `origin/claims`) and is freshly pulled.
2. **Enumerate candidates**: goals with `phase ≡ translate`, `status ≡ open`, fewer than 2 live claims by distinct other agents (live = `now ≤ ts+ttl`, computed by `tools.gate_b.claims` via an inline `python3` helper — the script never reimplements record parsing), no live claim by self, and no existing `translations/<goal>.<AGENT_ID>.aisp` on main.
3. **Select**: first candidate in lexicographic goal-id order (Phase 0 has no affinity data; deterministic order makes trials reproducible — deliberate collision pressure comes from agents starting simultaneously).
4. **Claim**: write the claim record (SPEC-003-B; `ts` = now UTC, `ttl` from config) in the claims worktree; commit `claim: <goal> <agent>`; push. On rejected push: `git pull --rebase`; if the goal now has ≥ cap live claims (or a live claim by self would be duplicated), emit a `collision` event and go to step 3 with the next candidate; otherwise push again.
5. **Translate**: `timeout "$UNSORRY_WALL" claude -p "<prompt>" --model "$UNSORRY_MODEL" --output-format text` where the prompt is `swarm/prompts/translate.md` + the backlog statement body. No tools are allowed for translation (pure text task). The independence rule (protocol `⟦Γ:Fidelity⟧`): the script never feeds existing translations into the prompt, and the prompt forbids consulting them.
6. **Sanity-check output**: single non-empty line; `python3 -m tools.fidelity normalize -` must succeed on it; the rendered record must pass `python3 -m tools.gate_b validate` on a temp tree. Failure ⇒ one retry (fresh call), then give up: `release` claim, emit `translate-failed` event, exit 1 (`--once`) or continue.
7. **Write record** `translations/<goal>.<AGENT_ID>.aisp` (SPEC-003-C template).
8. **Converge if second**: if `translations/<goal>.<other>.aisp` exists on main, run `python3 -m tools.fidelity diff` on the two records. Match ⇒ edit `goals/<goal>.aisp`: `status≜translated`, `sha≜<sha>`; emit `matched` event. Mismatch ⇒ `status≜flagged`; emit `flagged` event.
9. **Check in**: branch `feature/goal-<goal>-tr-<AGENT_ID>` from `origin/main`; commit the translation record (+ goal record edit if step 8 ran); push; `gh pr create` (title `tr(<goal>): translation by <AGENT_ID>`); `gh pr merge --auto --squash`.
10. **Release** the claim (remove file in claims worktree, commit `release: <goal> <agent>`, push).
11. **Metrics**: append one JSON line per event to `$UNSORRY_WORKDIR/metrics.jsonl`: `{"event": "...", "goal": "...", "agent": "...", "ts": "...Z"}` with events `claimed`, `collision`, `translated`, `translate-failed`, `matched`, `flagged`, `pr-opened`, `released`. The Phase-0 observer aggregates these files; nothing else reads them.

## Quality bar

- `bash` with `set -euo pipefail`; shellcheck-clean (CI job installs shellcheck).
- Pure functions (`agent-id` generation/validation, claim rendering, candidate filtering given a fixture tree, goal-record status rewrite) factored so `--self-test` exercises them hermetically (temp dirs, injected clock; no network, no claude).
- All git interactions with `origin` are confined to: fetch/pull, push to `claims`, push of `feature/goal-*` branches, `gh pr` calls. The script never pushes to `main`.
- Exit codes: 0 success or nothing-to-do; 1 cycle failure; 2 configuration error (not at repo root, missing tools, unauthenticated `gh`).

## Acceptance criteria

1. `--self-test` green; shellcheck clean; `bash -n` clean.
2. `--dry-run --translate-only` on the repo prints a candidate goal and claims nothing.
3. A full `--once --translate-only --goal <id>` run on a real goal produces: a claim on the claims branch, a translation PR that passes Gate B, a release commit — observable end-to-end (this is exercised live in the Stage-2 trial, W2).
4. With two translations present and matching, the goal record on the PR branch carries `status≜translated` and the correct `sha`.
