# SPEC-007-A: Agent Loop Script (`swarm/agent.sh`)

Implements: [ADR-006](../ADR-006-Gate-A-Soundness-Enforcement.md), [ADR-007](../ADR-007-Agent-Identity-and-Budgets.md), [ADR-022](../ADR-022-Local-Provider-Smoke-Mode.md) · Status: Living · Updated: 2026-06-13

Scope: **translation-only mode** (Phase 0), **prove mode** (Phase 1), and a local-only proof-provider smoke mode. The two swarm modes share the pull, select, claim, work, verify, check-in, release, and metrics skeleton. The local smoke reuses only proof generation and verification; it has no coordination or remote side effects.

## Invocation

```
./swarm/agent.sh --translate-only [--once] [--goal <id>] [--dry-run]
./swarm/agent.sh --prove [--once] [--goal <id>] [--provider claude|codex] [--dry-run]
./swarm/agent.sh --prove-local [--goal <id>] [--provider claude|codex|gemini|openai]
./swarm/agent.sh --dispatch-queue [--once] [--dry-run]
./swarm/agent.sh --self-test
```

| Flag | Meaning |
|---|---|
| `--translate-only` | Phase-0 mode: only `phase ≡ translate`, `status ≡ open` goals are candidates |
| `--prove` | Phase-1 mode: only `phase ≡ prove`, `status ≡ open`, not-already-proved goals are candidates. Mutually exclusive with `--translate-only`; exactly one mode (or `--self-test`) is required |
| `--prove-local` | Prove the highest-ranked open, unproved goal from local `HEAD`, or the explicit `--goal`, in a preserved detached worktree. Performs no fetch, claim, push, PR, GitHub, metrics, decomposition, or affinity operation |
| `--dispatch-queue` | Open queued proof branches as PRs when the ADR-058 submission governor admits more verifier work |
| `--provider <name>` | Proof provider. Coordinated `--prove` supports `claude` (default) and `codex`; `--prove-local` additionally supports experimental `gemini` and `openai` providers |
| `--once` | Run exactly one cycle then exit (default: loop until no claimable goal or budget spent) |
| `--goal <id>` | Restrict selection to one goal (trial orchestration) |
| `--dry-run` | Stop after selection: print the goal that would be claimed, claim nothing |
| `--self-test` | Run the built-in pure-function tests and exit (0 green / 1 red) |

Must be run from the repository root (script verifies `swarm/protocol.aisp` exists and the `origin` remote points at an unsorry repo). `--prove` additionally requires `lake` on `PATH` (the verify step builds the proof locally).

## Environment

| Var | Default | Meaning |
|---|---|---|
| `UNSORRY_AGENT_ID` | contents of `~/.unsorry/agent-id` (created on first run: `<short-hostname>-<4 hex>`) | Swarm identity (ADR-007) |
| `UNSORRY_SOLVER` | authenticated `gh api user` login | GitHub handle credited in new verified proof index entries |
| `UNSORRY_PROVIDER` | `claude` | Provider for `--prove` or `--prove-local` |
| `UNSORRY_MODEL` | `sonnet` for translation; `fable` for Claude prove; provider default for Codex; `gpt-4o` for OpenAI | Model for translation/proof calls |
| `UNSORRY_WORKDIR` | `~/.unsorry/work` | Holds the claims-branch worktree and `metrics.jsonl` |
| `UNSORRY_LOCAL_WORKTREE` | fresh `/tmp/unsorry-prove-local-*` path | Exact preserved worktree path for `--prove-local` |
| `UNSORRY_WALL` | `1800` | Wall-clock seconds per cycle (`timeout` around the claude call) |
| `UNSORRY_TTL` | read from `tools/gate_b/config.py` (7200) | Claim TTL; the script reads the config value — never hardcodes it (DRY with the contract) |
| `UNSORRY_ATTEMPTS` | `3` for `--prove` and `--prove-local`; otherwise read from `tools/gate_b/config.py` `BUDGET_ATTEMPTS` (2) | Prove build/audit attempts; later attempts receive the previous build/audit error in the prompt. |
| `UNSORRY_SUBMISSION_GOVERNOR` | `1` for coordinated `--prove` | Enables the live submission governor. Set `0` only for an operator-approved override. `--prove-local` and `--dry-run` never create remote work and are exempt. |
| `UNSORRY_SUBMISSION_FREEZE` | `0` | Emergency coordinated-`--prove` pause. Truthy values make the agent exit cleanly before claim, unblock, decompose, demote, or proof PR creation. |
| `UNSORRY_SUBMIT_MODE` | `queue` | Coordinated `--prove` submit mode. `queue` pushes a verified branch under `queued/prove/<goal>/...` without opening a PR. `pr` restores the older immediate auto-merge PR behavior for deliberate operator exceptions. |
| `UNSORRY_DISPATCH_LIMIT` | `1` | Maximum queued proof branches `--dispatch-queue` opens per pass. `--once` also limits dispatch to one branch. |
| `UNSORRY_GOVERNOR_WAIT` | `300` | When positive and not `--once`, coordinated `--prove` and `--dispatch-queue` sleep this many seconds and poll again after a governor pause or empty queue. |
| `UNSORRY_MAX_OPEN_PROVE_PRS` | `40` | Pause coordinated `--prove` when this many open `prove(...)` PRs already exist. Set `-1` to disable this limit. |
| `UNSORRY_MAX_GATE_A_IN_FLIGHT` | `20` | Pause coordinated `--prove` when queued plus in-progress `gate-a.yml` runs reach this count. Set `-1` to disable this limit. |
| `UNSORRY_GOVERNOR_SCAN_LIMIT` | `200` | Maximum PR/run rows fetched for each governor query. |

Authentication: the selected provider CLI must be authenticated, or
`OPENAI_API_KEY` must be set for `openai`; `gh` must be authenticated for PR
creation.

Swarm execution requires the repository root with local `main` checked out and equal to the fetched `origin/main` tip. Candidate enumeration reads the local checkout, while proof, translation, convergence, decomposition, unblock, and affinity PR worktrees all branch from `origin/main`; rejecting feature branches and local-only `main` commits prevents an agent from claiming an unmerged goal that cannot exist in its PR worktree. Local smoke is exempt because it branches its worktree from local `HEAD` and never enters coordination.

Coordinated Codex proving uses the same claim, verification, PR, auto-merge,
failure-classification, and decomposition lifecycle as Claude. Codex proof
attempts run in a writable workspace sandbox; decomposition runs read-only.
Because claims and result branches are pushed through `origin`, this mode
requires write access to the shared repository. A contributor working only
from a fork uses `--prove-local`.

## Local provider smoke

`--prove-local [--goal <id>]` is explicitly disconnected from the swarm lifecycle. It verifies that a provider can perform the proof work before that provider is trusted with claims or PRs:

1. If `--goal` is absent, select the highest-ranked open, unproved local goal using the production affinity/gap ranking but no claim filtering. Validate that `goals/<id>.lean` and `.aisp` exist at local `HEAD`.
2. Create a detached worktree from local `HEAD`; no `git fetch` occurs.
3. Run the standard proof prompt through the selected provider. Claude keeps the existing restricted tool list. Codex runs non-interactively with `codex exec`, `workspace-write`, ephemeral session state, ignored user configuration/rules, and no approval prompts. The launcher prepends Homebrew paths so an obsolete NVM Node does not break the installed CLI.
4. After every provider call, reject any changed or untracked path except `library/Unsorry/<CamelName>.lean`.
5. Run the same cache restore, strict library build, axiom audit, generated statement-binding obligation, and library-options lint as swarm prove mode.
6. Remove the generated binding helper and preserve the worktree whether the proof succeeds or fails. Print the path and an inspection command.

Local smoke defaults to the same three-attempt proof budget as coordinated prove; `UNSORRY_ATTEMPTS` can override it. Codex defaults to its configured model and `high` reasoning unless `UNSORRY_MODEL` or `UNSORRY_EFFORT` is set. A requested Codex `ladder` maps to `medium → high → xhigh`; Claude retains `high → xhigh → max`. Gemini keeps the retry budget but mutes effort at the CLI because `gemini` has no `--effort` flag.

## Cycle (translate-only)

1. **Pull** `main`; ensure the claims worktree exists (`git worktree add "$UNSORRY_WORKDIR/claims-branch" claims` tracking `origin/claims`) and is freshly pulled.
1b. **Convergence sweep** (claims nothing): goals with `phase ≡ translate`, `status ≡ open` that already carry `translations/<goal>.<agent>.aisp` records by ≥ 2 distinct agents on `origin/main` were translated in overlapping PRs — each check-in saw no sibling, so step 8 never ran, and the goal would otherwise sit `open` forever while still attracting claims. For each such goal: run `python3 -m tools.fidelity diff` on the two records (with ≥ 3 present, diff the two lexicographically-first agent ids and note the anomaly in the metrics event); rewrite `goals/<goal>.aisp` exactly as in step 8 (`status≜translated` + `sha≜<sha>` on match, `status≜flagged` on mismatch — only those lines); branch `feature/goal-<goal>-converge-<AGENT_ID>[-<suffix>]` from `origin/main`; commit; push; `gh pr create`; `gh pr merge --auto --squash`; emit a `converged` event. No claim is taken: convergence is deterministic janitor work on already-public data, so a duplicate sweep by a racing agent produces a byte-identical edit whose PR merges cleanly or fails fast — both harmless. At most one sweep attempt per goal per session.
2. **Enumerate candidates**: goals with `phase ≡ translate`, `status ≡ open`, fewer than 2 live claims by distinct other agents (live = `now ≤ ts+ttl`, computed by `tools.gate_b.claims` via an inline `python3` helper — the script never reimplements record parsing), no live claim by self, no existing `translations/<goal>.<AGENT_ID>.aisp` on main, and fewer than 2 translations by distinct agents on main (a goal that already has two needs the step-1b sweep, not a third translation).
3. **Select**: first candidate in lexicographic goal-id order (Phase 0 has no affinity data; deterministic order makes trials reproducible — deliberate collision pressure comes from agents starting simultaneously).
4. **Claim**: write the claim record (SPEC-003-B; `ts` = now UTC, `ttl` from config) in the claims worktree; commit `claim: <goal> <agent>`; push. On rejected push: re-fetch and rebuild the claim commit from scratch on the hard-reset `origin/claims` tip (up to 3 retries); if the goal now has ≥ cap live claims, emit a `collision` event and go to step 3 with the next candidate; otherwise push again. Every exit path leaves the claims worktree hard-reset to `origin/claims` — no unpushed local commits survive into the next cycle.
5. **Translate**: `timeout "$UNSORRY_WALL" claude -p "<prompt>" --model "$UNSORRY_MODEL" --output-format text` where the prompt is `swarm/prompts/translate.md` + the backlog statement body. No tools are allowed for translation (pure text task). The independence rule (protocol `⟦Γ:Fidelity⟧`): the script never feeds existing translations into the prompt, and the prompt forbids consulting them.
6. **Sanity-check output**: single non-empty line; `python3 -m tools.fidelity normalize -` must succeed on it; the rendered record must pass `python3 -m tools.gate_b validate` on a temp tree. Failure ⇒ one retry (fresh call), then give up: `release` claim, emit `translate-failed` event, exit 1 (`--once`) or continue.
7. **Write record** `translations/<goal>.<AGENT_ID>.aisp` (SPEC-003-C template).
8. **Converge if second**: if `translations/<goal>.<other>.aisp` exists on main, run `python3 -m tools.fidelity diff` on the two records. Match ⇒ edit `goals/<goal>.aisp`: `status≜translated`, `sha≜<sha>`; emit `matched` event. Mismatch ⇒ `status≜flagged`; emit `flagged` event.
9. **Check in**: branch `feature/goal-<goal>-tr-<AGENT_ID>[-<suffix>]` from `origin/main`; commit the translation record (+ goal record edit if step 8 ran); push; `gh pr create` (title `tr(<goal>): translation by <AGENT_ID>`); `gh pr merge --auto --squash`. The `<suffix>` (6 hex of entropy, also used by the step-1b converge branch) makes feature-branch names unique per cycle: `origin` retains feature branches from failed and merged attempts, so a retried goal reusing the deterministic name would be rejected non-fast-forward by its own stale remote ref. PR titles already identify goal + agent, so the branch name needs no stability.
10. **Release** the claim (remove file in claims worktree, commit `release: <goal> <agent>`, push; same re-entrant retry as step 4 — re-fetch and rebuild the release commit from scratch on the hard-reset `origin/claims` tip, hard-reset on final failure and let the TTL reap the claim).
11. **Metrics**: append one JSON line per event to `$UNSORRY_WORKDIR/metrics.jsonl`: `{"event": "...", "goal": "...", "agent": "...", "ts": "...Z"}` with events `claimed`, `collision`, `translated`, `translate-failed`, `matched`, `flagged`, `converged`, `pr-opened`, `released`. The `converged` event (step 1b) additionally carries `"outcome": "matched"|"flagged"` before `"ts"`, plus `"translations": "<n>"` when an anomalous third distinct-agent record was present. The Phase-0 observer aggregates these files; nothing else reads them.

## Cycle (prove)

A `prove`-phase goal carries `goals/<id>.lean` — a `theorem <name> <signature> := by sorry` — and no AISP statement. The cycle reuses the translate skeleton's claim/PR/release plumbing; only the work and verify steps differ.

0. **Admission governor**: after syncing `main` and before any claim or PR-producing maintenance work, the coordinated `--prove` loop checks the live operations lane. If `UNSORRY_SUBMISSION_FREEZE` is truthy, if open `prove(...)` PRs are at or above `UNSORRY_MAX_OPEN_PROVE_PRS`, or if queued plus in-progress `gate-a.yml` runs are at or above `UNSORRY_MAX_GATE_A_IN_FLIGHT`, the agent exits 0 without claiming work. GitHub API read failures fail closed for coordinated `--prove`: when queue pressure cannot be observed during a flood, the safe action is to avoid adding new verifier demand. `--prove-local` and `--dry-run` are exempt because they do not create remote work.
1. **Pull** `main`; refresh the claims worktree (identical to translate step 1). No convergence sweep — that is a translate-only step.
2. **Enumerate candidates**: goals with `phase ≡ prove`, `status ≡ open`, fewer than `config.PROVE_CLAIM_CAP` (= 1) live claims by distinct other agents, no live claim by self, and **not already proved**. A goal is *proved* iff a `library/index/<sha>.aisp` entry names it (`goal≜<id>`) — the index entry is the authoritative proved marker (the merge edits both the goal record and the index, but the index entry is what a racing agent on a stale checkout can still see). Lexicographic goal-id order.
3. **Select**: first candidate in lexicographic goal-id order (same rationale as translate).
4. **Claim**: identical first-push-wins plumbing as translate step 4, but the post-rebase recheck uses `config.PROVE_CLAIM_CAP` (cap 1, vs translate's cap 2) — a prove goal admits a single live claim by a distinct agent.
5. **Prove**: drive `claude` to write a **new** library module `library/Unsorry/<CamelName>.lean` (CamelName = the goal id with `-`-separated parts capitalized and joined: `nat-add-comm-thm` → `NatAddCommThm`) that **re-states the same theorem** (same name, same signature, imports the goal file needs plus whatever the proof needs) and proves it with no `sorry`. The call is `timeout "$UNSORRY_WALL" claude -p "<swarm/prompts/prove.md + statement + target path + module/theorem names>" --model "$UNSORRY_MODEL" --output-format text --allowedTools "Read,Edit,Write,Bash(lake build *),Bash(lake env *),Bash(lake exe *),Bash(git diff *)"`. `--max-turns` is **not** passed: it does not exist on `claude` 2.1.170 (the translate cycle dropped it for the same reason); the `$UNSORRY_WALL` `timeout` bounds the call. The prover may run read-only `lake`/`git diff` to check its own work; it writes only the target module.
6. **Verify locally, before any PR** (the agent self-verifying, per ADR-006 and the design doc's step 6). The proof worktree is a fresh checkout with **no `.lake`** (it is gitignored), so before the first build the cycle runs `lake exe cache get` once in the worktree to restore the prebuilt mathlib oleans — without it, `lake build UnsorryLibrary --wfail` recompiles all of mathlib from source and blows the attempt budget (observed in phase1-run-001; a warm global cache makes the fetch a ~20 s no-op). The fetch is best-effort: on failure the build still works, just slowly, so the cycle warns and continues. Then all three must pass on the proof worktree, for module `Unsorry.<CamelName>`: (a) `lake build UnsorryLibrary --wfail` (zero-sorry, zero-warning bar); (b) `lake exe axiom_audit Unsorry.<CamelName>` — whitelist only, **no** `--allow-sorry`; (c) `python3 -m tools.gate_a.check_library_options library`. Up to `config.BUDGET_ATTEMPTS` (= 2, via `UNSORRY_ATTEMPTS`) attempts: on a failed build/audit the combined output is fed back to one fresh `claude` call, then give up.
7. **Index the proof**: compute the proved statement's **content address** — `sha = sha256(<normalized Lean statement string>)` (lowercase hex). The normalized Lean statement is the goal `.lean`'s `theorem`/`lemma` declaration with `import`/`--`-comment lines dropped, the proof (`:=` body) cut, and all whitespace collapsed to single spaces. This is the prove analogue of `tools/fidelity` `statement_sha` for translate goals: a translate goal has an AISP canonical statement to address (and its index sha is `tools/fidelity` `statement_sha` of that), but a prove goal has only its Lean text, so the index is keyed by the sha of that normalized Lean statement string (theorem name + signature included). The rule is deterministic and, on the seeded 20-goal backlog, collision-free. Write `library/index/<sha>.aisp` (same shape as existing entries; `tags≜⟨⟩` and `use≜0; aff≜0` start empty).
8. **Mark the goal proved**: edit `goals/<id>.aisp` via the existing `rewrite-goal` helper — `status≜proved` + `sha≜<sha>`, only those two lines.
9. **Check in or queue**: in `UNSORRY_SUBMIT_MODE=pr`, branch `feature/goal-<goal>-prove-<AGENT_ID>-<suffix>` from `origin/main`; commit the library module + index entry + goal edit; Gate-B-validate the tree; push; `gh pr create` (title `prove(<goal>): <name> by <AGENT_ID>`); `gh pr merge --auto --squash`. In `UNSORRY_SUBMIT_MODE=queue`, branch `queued/prove/<goal>/<AGENT_ID>-<suffix>` from `origin/main`; commit the exact same verified tree; Gate-B-validate it; push it to `origin`; do **not** create a PR or arm auto-merge. Candidate selection treats a queued proof branch for a goal as in-flight work, so another producer does not duplicate it while it waits for dispatch.
10. **Release** the claim (identical re-entrant plumbing to translate step 10).
11. **On prove failure** (budget/attempts spent, build/audit never passed, or check-in failed): release the claim and emit a `prove-failed` event. **Phase 1 keeps it simple — no decomposition.** The design doc's decomposition path (commit a `decompositions/` record, split the goal into sub-goals) is **Phase 2**; in Phase 1 a prove failure is just release + flag.
12. **Metrics**: events `claimed`, `collision`, `proved`, `prove-failed`, `queued`, `pr-opened`, `released` — same JSON line format as translate. `proved` and `pr-opened` are emitted on an immediate PR check-in; `proved` and `queued` are emitted on a successful queued-branch check-in; `prove-failed` on the failure path.

## Queue Dispatch

`./swarm/agent.sh --dispatch-queue` is the intake valve for queued proof
branches. It fetches `origin/queued/prove/*`, skips branches that already have
a PR, checks the same ADR-058 submission governor used by producers, and opens
at most `UNSORRY_DISPATCH_LIMIT` PRs per pass. Each dispatched PR uses the
queued branch's commit subject as its title and arms the same auto-merge policy
as immediate `pr` mode.

When `UNSORRY_GOVERNOR_WAIT` is positive, producer and dispatcher loops stay
resident: producers poll again after a governor pause or empty prove queue, and
dispatchers poll again after a pass with no admitted dispatch.

This path is compatible with the existing flow. Already-open proof PRs remain
ordinary PRs and drain through Gate A. Queued branches add no Gate A load until
the dispatcher opens them, and the dispatcher counts the existing open PRs and
Gate A queued/in-progress runs before adding more.

## Index-sha rule (prove)

`library/index/<sha>.aisp` is keyed by the **content address of the goal's statement**. Two cases, both `sha256` lowercase hex:

- **translate goal** → `sha = tools/fidelity` `statement_sha` of the goal's canonical AISP statement (`SHA256(norm(stmt))`, the same value the fidelity gate writes to `goals/<id>.aisp`'s `sha≜` on convergence).
- **prove goal** → `sha = sha256(<normalized Lean statement string>)`, where the normalized string is the goal `.lean`'s theorem declaration minus imports/comments and minus the proof, with whitespace collapsed (see prove step 7). A prove goal has no AISP statement, so the Lean statement string is the addressable artifact.

The two cases never collide in practice (different namespaces of content) and each is deterministic given the goal file.

## Quality bar

- `bash` with `set -euo pipefail`; shellcheck-clean (CI job installs shellcheck).
- Pure functions (`agent-id` generation/validation, claim rendering, candidate filtering and sweep detection given a fixture tree, goal-record status rewrite, convergence rewrite; plus the prove helpers: CamelCase module naming, Lean statement/name extraction, index-sha derivation, prove-candidate filtering, "already proved ⇒ not a candidate", goal→proved rewrite, index-entry rendering) factored so `--self-test` exercises them hermetically (temp dirs, injected clock; no network, no claude, **no lake**). A real `lake` build is exercised only in the live prove smoke / CI, never in `--self-test`.
- All git interactions with `origin` are confined to: fetch/pull, push to `claims`, push of `feature/goal-*` branches, `gh pr` calls. The script never pushes to `main`.
- Caps, TTL and budgets come from `tools/gate_b/config.py` (`TRANSLATE_CLAIM_CAP`, `PROVE_CLAIM_CAP`, `TTL_SECONDS`, `BUDGET_ATTEMPTS`) — never hardcoded (DRY with the contract; `tests/test_contract_constants.py` keeps config in lockstep with `swarm/protocol.aisp`).
- Re-entrant push handling: no cycle exits leaving stranded local state for the next one — every claims-branch push failure (and every cycle start, step 1) ends with the claims worktree hard-reset to `origin/claims`, a worktree left mid-rebase by a killed cycle is recovered automatically, and per-cycle feature-branch suffixes make non-fast-forward collisions with the agent's own remote refs structurally impossible.
- Exit codes: 0 success or nothing-to-do; 1 cycle/proof failure; 2 configuration error (not at repo root, missing tools, unauthenticated `gh`); 3 provider infrastructure failure.

## Acceptance criteria

1. `--self-test` green; shellcheck clean; `bash -n` clean.
2. `--dry-run --translate-only` on the repo prints a candidate goal and claims nothing.
3. A full `--once --translate-only --goal <id>` run on a real goal produces: a claim on the claims branch, a translation PR that passes Gate B, a release commit — observable end-to-end (this is exercised live in the Stage-2 trial, W2).
4. With two translations present and matching, the goal record on the PR branch carries `status≜translated` and the correct `sha`.
5. An `open` translate goal with two distinct-agent translations already merged on main is converged by the step-1b sweep, not re-translated: `--self-test` covers sweep detection (2 translations listed; 1 translation or `status≜translated` not listed), the exclusion of such a goal from step-2 candidates, and both convergence rewrite outcomes (matched ⇒ `status≜translated` + `sha`, flagged ⇒ `status≜flagged`, nothing else touched) — all hermetically; live, the convergence PR's only edit is the goal record.
6. `--dry-run --prove` on the repo prints a candidate `prove` goal and claims nothing.
7. `--self-test` covers the prove-cycle pure functions: CamelCase module naming, Lean statement/name extraction, index-sha determinism (stable under whitespace/proof variation), prove-candidate filtering (phase ≡ prove / open / uncapped by `PROVE_CLAIM_CAP` / not self-claimed), "already proved ⇒ not a candidate" (an index entry naming the goal excludes it), the goal→`proved` rewrite (`status≜proved` + `sha`, nothing else), and that a rendered index entry + proved goal pass Gate B — all hermetically (no `lake`).
8. A full `--once --prove --goal <id>` run on a real `prove` goal produces: a claim on the claims branch, a new `library/Unsorry/<CamelName>.lean` that passes `lake build UnsorryLibrary --wfail` and `lake exe axiom_audit Unsorry.<CamelName>` (whitelist only), a `library/index/<sha>.aisp` entry, a goal flipped to `status≜proved`, a prove PR that passes Gate B, and a release commit — observable end-to-end (exercised live in the Stage-5 trial, W4, and against a local bare-origin fixture during development).
9. `--prove-local --provider codex` automatically selects an open goal; with or without an explicit `--goal`, it makes no remote or coordination changes, preserves its detached worktree, rejects provider edits outside the target module, and returns 0 only after the standard local proof verification passes.
