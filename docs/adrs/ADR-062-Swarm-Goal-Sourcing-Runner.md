# ADR-062: Swarm Goal-Sourcing Runner

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-062 |
| **Initiative** | contributor scale / problem supply |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-17 |
| **Status** | Proposed |

## Context

ADR-060 / SPEC-060-A shipped the contributor-facing `unsorry-goal-sourcing`
skill, the `tools/sourcing/gen_triples.py` triple assembler, and a `--sourcing`
leaderboard mode — everything a human (or an agent in an interactive session)
needs to *source new open goals*. What it did not ship is an unattended runner:
the maintainer follow-up on PR #1837 asked for "a bash script that is run like
the `./swarm/agent.sh` that will fire up claude and run through a cycle of goal
sourcing."

The swarm already has exactly this shape for the *downstream* half of the queue.
`swarm/agent.sh` (ADR-006, ADR-007, SPEC-007-A) is the prove/translate runner: it
does not contain the proving intelligence — that lives in `swarm/prompts/prove.md`
and the `unsorry-proof-authoring` skill — it is the *harness* around one Claude
call per cycle (preflight, prompt assembly, a `timeout`-wrapped invocation,
ADR-016 infrastructure-failure classification, ADR-059 fetch resilience, exit
codes 0/1/2/3 that `swarm/supervise.sh` interprets). There is no equivalent
harness for *sourcing*: the only way to drive a sourcing cycle today is to open
Claude by hand and paste the skill.

Two differences from the prove arm shape the design:

1. **No empty-pool terminator.** `agent.sh` loops until the claimable pool is
   empty, then exits 0; `supervise.sh` waits for in-flight PRs and re-runs. A
   sourcing cycle has no such fixed point — Claude can always invent another
   theorem — so an unbounded loop would open `chore(sourcing):` PRs forever.
2. **No claim branch.** ADR-060 chose *no-pre-claim + merge-time dedup* for
   sourcing (the claims branch is prove-only and fork-inaccessible). So the
   runner needs no claim/release plumbing; its only coordination duty is to hand
   Claude a fresh `origin/main` goal-slug snapshot to deduplicate against.

This is a maintainer-side automation, not the fork path. ADR-060 explicitly
defers advertising sourcing "at ludicrous scale" until ADR-054 quota/abuse
controls land; a runner a maintainer invokes against their own quota — exactly
as they already invoke `agent.sh` — does not cross that line.

## WH(Y) Decision Statement

**In the context of** a complete, validated goal-sourcing skill (ADR-060) that
can only be driven by hand, and an existing prove/translate runner (`agent.sh`)
whose harness shape — Claude-per-cycle, preflight, timeout, infra classification,
fetch resilience, supervise-compatible exit codes — is exactly what unattended
sourcing needs,

**facing** a maintainer request to run sourcing "like `agent.sh`," the fact that
sourcing has no empty-pool fixed point (so the prove arm's loop-until-empty
default would open PRs without bound) and no claim branch (so the prove arm's
claim/release plumbing does not apply), and ADR-060's standing caution that
sourcing must not be opened to broad scale before ADR-054,

**we decided for** a **new sibling script `swarm/sourcing.sh`** (ADR-062,
SPEC-062-A) that is a thin harness around one Claude call running the
`unsorry-goal-sourcing` skill per cycle, driven by a new
`swarm/prompts/source.md` playbook prompt; that **defaults to a bounded run**
(`UNSORRY_SOURCING_CYCLES`, default 1; `--cycles N` overrides; `--once` forces 1)
because there is no empty-pool terminator; that injects a freshly-fetched
`origin/main` goal-slug snapshot plus the theme, the `≤50`-goal cap (SPEC-060-A
PR discipline), and the solver handle into the prompt; that reuses `agent.sh`'s
conventions verbatim — `[sourcing.sh]` logging, `require_repo_root` /
`require_main_checkout` / `require_main_matches_origin` preflight, the ADR-016
health probe + `classify_call_failure`, the ADR-059 `git_fetch_retry` backoff,
and exit codes **0** ok / **1** cycle-fail / **2** config / **3** infra so
`supervise.sh` can wrap it unchanged; that scopes Claude's `--allowedTools` to the
sourcing toolchain (`tools.sourcing.*`, `lake build UnsorryGoals`, scratch
elaboration, fetch/dedup git, and the single `gh pr` call) and **cannot** touch
`library/`, the lakefiles, the gates, or the harness; and that ships
**shellcheck-clean + hermetic-self-test green** under the SPEC-007-A bar, wired
into `agent-lint.yml` alongside `agent.sh`/`supervise.sh`,

**and neglected** adding a `--sourcing` mode to `agent.sh` (rejected — the
maintainer asked for a script "like agent.sh," not inside it; sourcing shares no
claim/worktree/decomposition machinery with the prove loop, so a mode would bolt
an unrelated control flow onto an already 5k-line file and widen the blast radius
of every prove change), defaulting to an unbounded loop like the prove arm
(rejected — no empty-pool fixed point means it never stops; bounded-by-default
with an explicit `--cycles` is the safe shape), having the harness own the
git/branch/PR plumbing as `agent.sh` does for proofs (rejected for the MVP —
sourcing has no claim race or target-file guard to enforce in bash, and the skill
already documents the `chore(sourcing):` PR step for Claude; letting Claude open
the scoped PR keeps the harness small and is faithful to "fire up claude and run
a cycle"), and supporting non-Claude providers (rejected for now — the skill is
Claude-authored and leans on Claude tool use; other providers `die_config` until
demand exists),

**to achieve** an unattended, supervise-compatible way for a maintainer to run
the proven sourcing skill on a schedule or in the background — the sourcing
counterpart to the prove runner — that keeps the difficulty bar and the
conflict model of ADR-060 intact,

**accepting that** the runner opens real PRs autonomously (bounded by the cycle
count, the `≤50`-goal cap, and `--dry-run` for inspection), that it is a
maintainer tool gated on the maintainer's own quota rather than the fork path
(broad rollout still waits on ADR-054), that Claude owns the in-cycle git/PR
steps under a scoped allowlist rather than the harness owning them, and that a
small amount of pure helper logic (the ADR-059 backoff schedule, the ADR-016
classifier, the health probe) is duplicated from `agent.sh` rather than extracted
into a shared `swarm/lib.sh` — a deliberate deferral, since refactoring the
5k-line prove runner to share a library is its own ADR and would balloon this
change across a CODEOWNERS-owned surface.

## What the runner does (summary; full contract in SPEC-062-A)

1. **Preflight** — repo root, `main` checked out and equal to `origin/main`
   (after an ADR-059 retrying fetch), `gh` authenticated, Claude callable
   (ADR-016 health probe). `--dry-run` skips the network preflight and the call.
2. **One cycle = one Claude call** — assemble `source.md` + a runtime block
   (theme, `≤max-goals` cap, solver handle, fresh `origin/main` goal-slug
   snapshot to dedup against), then `timeout "$UNSORRY_WALL" claude -p … --model
   "$(resolve_model)" --allowedTools <sourcing scope>`.
3. **Bounded loop** — run `UNSORRY_SOURCING_CYCLES` cycles (default 1), refreshing
   `main` and sleeping `UNSORRY_SOURCING_INTERVAL` between them.
4. **Failure classification** — a fast failure with a dead health probe is
   infrastructure (exit 3, no penalty, ADR-016); otherwise a cycle failure
   (exit 1). Config problems exit 2. `supervise.sh` reads these unchanged.

## Consequences

- **Positive.** Sourcing gains the same unattended, resilient runner the prove
  arm has had since Phase 0; a maintainer can background it or schedule it.
- **Positive.** Reuses `agent.sh`'s battle-tested conventions and exit-code
  contract, so `supervise.sh` wraps it with no change.
- **Positive.** Bounded-by-default + `--dry-run` + a scoped allowlist keep an
  autonomous PR-opener inside the ADR-060 guardrails.
- **Negative.** A second runner duplicates a few pure helpers from `agent.sh`
  until a shared `swarm/lib.sh` is justified (its own ADR).
- **Negative.** Claude opens the PR under a broad-ish git/`gh` allowlist; the
  harness does not re-verify the PR contents (Gate B does, post-push).
- **Negative.** Broad/fork rollout still depends on ADR-054 quota controls; this
  runner is maintainer-side only.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Swarm goal-sourcing runner spec | Specification | specs/SPEC-062-A-Swarm-Goal-Sourcing-Runner.md |
| REF-2 | Contributor-Facing Goal-Sourcing Skill | Decision | ADR-060-Contributor-Goal-Sourcing-Skill.md |
| REF-3 | Agent Identity and Budgets (agent-loop home) | Decision | ADR-007-Agent-Identity-and-Budgets.md |
| REF-4 | Agent Loop Script | Specification | specs/SPEC-007-A-Agent-Loop-Script.md |
| REF-5 | Infrastructure-Failure Guard | Decision | ADR-016-Infrastructure-Failure-Guard.md |
| REF-6 | Fetch Resilience On Shared Object Store | Decision | ADR-059-Fetch-Resilience-On-Shared-Object-Store.md |
| REF-7 | Volunteer-Scale Claim Substrate | Decision | ADR-053-Volunteer-Scale-Claim-Substrate.md |
| REF-8 | Agent Identity, Quotas, and Reputation | Decision | ADR-054-Agent-Identity-Quotas-And-Reputation.md |
| REF-9 | Sourcing runner request | Issue | GitHub PR #1837 (maintainer follow-up comment) |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-17 |
