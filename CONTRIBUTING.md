# Contributing to unsorry

Agents and humans contribute the same way: **claim a goal, open a PR, and let the gates decide.** Nobody has to trust your machine — the Lean kernel re-verifies every contribution in CI (Gate A), so a careless or even adversarial PR cannot poison the library. Human review, where it happens at all, is for naming and duplication, never for correctness.

Four ways to contribute, in rough order of involvement:

1. [Run an agent](#running-an-agent) — point a Claude instance at the queue, or prove a goal yourself.
2. [Propose a target](#proposing-a-target) — suggest a theorem worth proving, or [source new ones at scale](#sourcing-new-targets-at-scale).
3. [Generate library fixtures](#generating-library-fixtures-at-scale) — batch-produce deterministically-proved lemma families with `tools/seedkit`.
4. [Sponsor an upstream](#upstreaming-to-mathlib) — take a proved lemma into mathlib (the one task that requires a human, by mathlib policy).

All work follows the [development protocols](#development-protocols): an ADR per significant decision, a spec per ADR, TDD, feature branches, and a changelog entry per release.

---

## Running an agent

> **Status: live.** The swarm has proved theorems not already in mathlib. Because the kernel re-checks everything in CI, you can run an agent against this repo without anyone trusting your machine.

**Prerequisites:** [Claude Code](https://claude.com/claude-code) (headless `claude`, authenticated — a subscription works, no API key required), the [Lean toolchain](https://leanprover-community.github.io/get_started.html) via `elan` (the pinned version installs automatically from `lean-toolchain`), the [`gh`](https://cli.github.com/) CLI authenticated, and Python 3.12.

```bash
git clone https://github.com/agenticsnz/unsorry && cd unsorry
lake exe cache get                 # fetch prebuilt mathlib (minutes; never builds from source)
lake build                         # verify the current library locally
python3 -m tools.gate_b validate . # check coordination artifacts (Gate B)
./swarm/run.sh                     # one dispatcher + one resilient prover (recommended)
```

`run.sh` runs the full governed flow: a prover that claims open goals, drives the provider to write a Lean proof, self-verifies locally (`lake build --wfail` + the axiom audit) and parks verified branches under `queued/prove/`; plus a dispatcher that opens those branches as auto-merge PRs when the submission governor (ADR-058) admits more Gate A work. Both loops poll every 300s when saturated or empty. It is equivalent to running the two loops yourself:

```bash
./swarm/agent.sh --prove          # verified branches under queued/prove/
./swarm/agent.sh --dispatch-queue # opens them as auto-merge PRs when the governor admits
```

Run exactly **one** dispatcher. For more provers, add `./swarm/supervise.sh --prove` only.

> **If the scheduled `queue-dispatcher` workflow is enabled, it already _is_ the one dispatcher** — `run.sh` would start a second. ADR-064 goal dedup keeps this mostly harmless (both skip a goal already proved or already PR'd) but they can race within a pass. So when the scheduled dispatcher is active, run a prover only (`./swarm/supervise.sh --prove`); use `run.sh` for a standalone deployment with no scheduled dispatcher.

The submission governor exits cleanly when there are already too many open proof PRs or queued/in-progress Gate A runs. Override only for a deliberate emergency exception (`UNSORRY_SUBMISSION_GOVERNOR=0`); force immediate-PR mode only with operator approval (`UNSORRY_SUBMIT_MODE=pr`).

**Useful flags:**

- `--once` — single cycle (omit to loop until budget is spent or no goal is claimable).
- `--dry-run` — show what would be claimed without claiming.
- `--prove-local [--goal <id>] --provider claude|codex|gemini|openai` — generate and fully verify a proof in a preserved worktree with no fetch/claim/push/PR (works from committed local `HEAD`). Without `--goal`, picks the highest-ranked open local target.
- `--translate-only` — run the Phase-0/1 formalisation loop instead of proving.
- `--provider codex|openai` — change provider (Claude default; Gemini is local-only). Point `--provider openai` at any OpenAI-compatible server (Ollama / vLLM / LM Studio / proxy) via `OPENAI_BASE_URL` — custom endpoints bypass the model allow-list (needs a tool-capable model for `--prove`).
- `-pi [<model>]` — resolve a model from pi-coder's `~/.pi/agent/models.json` to its endpoint/key/id and prove with it (forces `--provider openai`; ADR-025), e.g. `./swarm/agent.sh --prove --once -pi leanstral-2603`.
- `--self-test` — check your setup (hermetic; no network, no `claude`).

See [`tools/llm_providers/README.md`](tools/llm_providers/README.md) and [`docs/gemini-provider.md`](docs/gemini-provider.md).

**Proving one specific goal.** Target a single goal by kebab slug (e.g. `nat-add-comm`, or a benchmark goal — [#5643](https://github.com/agenticsnz/unsorry/issues/5643)) with `./swarm/run.sh --goal <id>` (standalone) or `./swarm/supervise.sh --prove --goal <id>` (swarm already up). The prover proves that goal plus any sub-lemmas it decomposes into, waits for the PR(s) to merge, and exits cleanly once the goal's scope is fully proved (`scope_closed`); `run.sh` also stops its background dispatcher on exit.

For unattended runs, [`./swarm/supervise.sh --prove --goal <id>`](swarm/supervise.sh) wraps the loop with backoff across infrastructure outages, in-flight merge waits, and PR hygiene (ADR-017), driving a goal tree to closure with one command.

### Proving from a fork (no write access)

You do **not** need write access to prove goals and have them merged. **Fork-native mode** ([ADR-068](docs/adrs/ADR-068-Fork-Native-Contribution-Mode.md) / [SPEC-068-A](docs/adrs/specs/SPEC-068-A-Fork-Native-Contribution-Mode.md)) is the non-contributor route — fork `agenticsnz/unsorry`, then run the swarm against your fork:

```bash
git clone https://github.com/<you>/unsorry && cd unsorry
./swarm/run.sh          # fork auto-detected: claimless prover, cross-repo PRs, no dispatcher
```

In fork mode the agent (auto-detected, or forced with `--fork` / `UNSORRY_FORK=1`):

- proves **claimlessly** — the `claims` branch is upstream-only, so it dedups read-only against upstream (skipping goals already proved or PR'd) and keeps your fork's `main` synced;
- pushes each verified branch to **your fork** and opens a **cross-repo PR** to `agenticsnz/unsorry`, where Gate A re-verifies it on the kernel (the same trust boundary as any other PR);
- leaves auto-merge to the upstream, which arms it on admissible fork PRs once gates are green.

**One-time first PR:** GitHub requires a maintainer to approve a *new* fork contributor's **first** Actions run; after that, PRs run and merge hands-off. Duplicate fork proofs only waste verifier compute (first-merge-wins), never soundness. For purely local proving with no PR, use `--prove-local`.

### Leaderboard credit

Before coordinated runs, make sure `gh auth status` shows the account that should receive credit, or set `UNSORRY_SOLVER=<github-handle>`. Git commit authorship and solver credit are intentionally separate: the leaderboard ranks verified proofs by explicit `solver≜` provenance first, falling back to git add-author attribution for older records (old source records are never rewritten). See the generated **[community proof statistics](docs/leaderboard.md)**, the **[visual leaderboard](docs/leaderboard.html)**, and `docs/metrics/{community-stats,leaderboard-ui,attribution-gaps}.json`. When changing `library/index/` or `proof-runs/` outside the agent loop, refresh views with `python3 -m tools.leaderboard --write .` and verify with `--check .`.

An agent session loads `swarm/protocol.aisp` (the coordination contract) plus the AISP grammar reference ([AI_GUIDE.md](https://github.com/bar181/aisp-open-core/blob/main/AI_GUIDE.md), ~19 KB) at start. Note: from 2026-06-15, headless `claude -p` on subscription plans draws from a separate Agent SDK credit pool — size your run accordingly.

### Model & effort policy

Proof-surface calls default to the most capable model (`fable`) on a progressive effort ladder (`high → xhigh → max`, one rung per attempt) — [ADR-013](docs/adrs/ADR-013-Model-Effort-Policy.md) / [ADR-015](docs/adrs/ADR-015-Progressive-Effort-Escalation.md). Override with `UNSORRY_MODEL` / `UNSORRY_EFFORT`; both degrade fail-soft on CLIs without `--effort`.

---

## Proposing a target

Open targets live on the **[targets board](docs/targets.md)** — theorems proven somewhere but not yet in mathlib, vetted for absence and stated in Lean. Pick one and prove it, or point an agent at the queue. To suggest a new one, open a [propose-target issue](.github/ISSUE_TEMPLATE/propose-target.md).

Sourcing and mathlib-absence checking are [ADR-012](docs/adrs/ADR-012-Backlog-Sourcing.md); absence is a grep **pre-filter**, not a proof (a target already in mathlib gets discharged by a one-line citation). Admitted targets must also pass a **machine triviality check** ([ADR-035](docs/adrs/ADR-035-Non-Trivial-Theorem-Enforcement.md)): `python3 -m tools.sourcing.check_triviality goals/<id>.lean` elaborates the statement under `import Mathlib` against a battery of one-shot tactics — anything a single `simp`/`aesop`/`decide` closes is not admitted. A genuine-but-automatable theorem can carry a `- **Nontrivial-override:** <reason>` line in its `backlog/<id>.md`.

**Benchmark contributors:** the registered benchmark suites — `putnam-v1`, `imo-v1`, `minif2f-v1`, `combibench-v1` (under [`targets/`](targets/)) — are imported as goal cohorts; prove one with `./swarm/run.sh --goal <id>`. Track: [#5643](https://github.com/agenticsnz/unsorry/issues/5643).

### Sourcing new targets at scale

To **source many new targets yourself** — the "make the problems harder and generate more of them" work ([ADR-060](docs/adrs/ADR-060-Contributor-Goal-Sourcing-Skill.md)) — use the **`unsorry-goal-sourcing` skill**. Working in this repo with [Claude Code](https://claude.com/claude-code) (or any agent), ask it to *source new targets* and point it at [`Skills/unsorry-goal-sourcing/SKILL.md`](Skills/unsorry-goal-sourcing/SKILL.md); that same file (plus its `references/`) is also a readable runbook for driving it by hand.

**The workflow — you create the problem, you don't prove it:**

1. Find a theorem **already proven somewhere** but **absent** from the pinned mathlib — never an open conjecture. Aim **hard** (difficulty ≥3): olympiad / PutnamBench / miniF2F, multivariate inequalities, the Freek-#50 Euler substrate.
2. Screen through the gates: `check_absence` (exit 0, record the mathlib rev) → type-checks (`lake build UnsorryGoals`) → `check_triviality` (exit 0) → its intended proof compiles (`lake env lean`).
3. Assemble the three-file goal triple with `python3 -m tools.sourcing.gen_triples --slug <id> --lean-sig '…' --statement '…' --difficulty 3 … --validate` (re-runs Gate B).
4. Open a PR titled **`chore(sourcing): …`** (≤50 goals per PR). Works **from a fork** — Gate B validates on GitHub-hosted runners, so no special access is needed; a maintainer just approves the first Actions run.

Sourcing earns its own credit on the **sourcing leaderboard** (`python3 -m tools.leaderboard --sourcing`; `docs/metrics/sourcing-leaderboard.json`), independent of who proves the goal — set `UNSORRY_SOLVER=<your-handle>` or confirm `gh auth status`.

### Generating library fixtures at scale

[`tools/seedkit/`](tools/seedkit/README.md) grows the **library** directly: it batch-generates parametric, kernel-verified lemma *families* (divisibility, residue, telescoping, Faulhaber, …) where each goal arrives **already proved** — statement and a deterministic `decide` / `induction; ring` proof minted together as a *fixture* ([ADR-086](docs/adrs/ADR-086-Seedkit-Fixture-Generation-Path.md)).

This is **not sourcing**: there is no open goal to solve, and these template goals sit at **difficulty 1**. Reach for it when you want cheap, sound, reusable library lemmas and regression fixtures; reach for the sourcing skill when you want *hard new problems*. Set `UNSORRY_SOLVER=<your-handle>` (seedkit refuses anonymous fixtures); each proof is recorded as `provider≜lean`. See [`tools/seedkit/README.md`](tools/seedkit/README.md) for families, gates, and batch drivers.

---

## Upstreaming to mathlib

Getting a proved lemma *into* mathlib is the one place a human is required, by [mathlib's AI-contribution policy](https://leanprover-community.github.io/contribute/index.html): AI use must be disclosed, the PR carries the `LLM-generated` label, and the author must understand the proof and write the PR and review replies **in their own words** — LLM-written conversation is not allowed, and autonomous LLM PRs get summarily closed.

So unsorry splits the work: the **machine** prepares an [upstream packet](docs/upstream/) (a `git apply`-able patch, gate evidence, a factual disclosure block) and a [one-command draft-PR helper](docs/upstreaming.md#step-by-step-with-the-commands); a human **sponsor** owns the understanding, the Zulip thread, the PR narrative, and the vouching. Full step-by-step: **[docs/upstreaming.md](docs/upstreaming.md)**. Autonomous unsorry→mathlib PRs are a permanent non-goal.

---

## Development protocols

Every change, however small, follows [`docs/protocols.md`](docs/protocols.md) (vendored from [cgbarlow/protocols](https://github.com/cgbarlow/protocols), ADR-001; see also [`CLAUDE.md`](CLAUDE.md)). These are non-negotiable:

- **One ADR per significant decision** in [`docs/adrs/`](docs/adrs/), in WH(Y) format with rejected alternatives recorded; a **spec** per implementation ADR in [`docs/adrs/specs/`](docs/adrs/specs/) captures the "how". ADRs are immutable — supersede, don't edit.
- **TDD** — tests before implementation. The agent loop (`./swarm/agent.sh --self-test`), the supervisor (`./swarm/supervise.sh --self-test`), and the Python tools (`python3 -m pytest tools -q`) all stay green.
- **Feature branch + PR for everything; no direct commits to `main`.** One logical change per branch (`feature/`, `fix/`, `docs/`, mirroring the PR kind) — never bundle (a harness fix must not ride a proof PR). Short-lived off `main`, squash-merged on green gates, deleted after.
- **Conventional, enforced PR titles** ([`docs/pr-labels.md`](docs/pr-labels.md), [ADR-026](docs/adrs/ADR-026-PR-Convention-Enforcement.md)). The type must be the **first token** — no bracket/tool prefixes (`[codex] ci: …` is rejected). Use a Conventional-Commits prefix (`feat:`, `fix:`, `docs:`, `chore:`, `ci:`, `test:`, `refactor:`, `perf:`, `build:`; scope optional, `:` required), or a swarm shape: `prove(<goal>):` (proved), `decompose(<goal>):` / `affinity(<goal>):` (not proved — split / demoted), `tr(<goal>):`, `converge(<goal>):`.
- **Changelog fragment** for every user-facing change ([Keep a Changelog](https://keepachangelog.com/) + SemVer): add `changelog.d/<category>-<slug>.md` rather than editing `CHANGELOG.md` (one file per change avoids parallel-PR conflicts; ADR-040). A release collates fragments with `python3 -m tools.changelog --release`; see [`changelog.d/README.md`](changelog.d/README.md). The advisory `pr-changelog` check is a non-blocking reminder, never a gate. (A single swarm proof needs no fragment.)
- **Production-ready code only** — no mocks, stubs, or placeholders in application code; defer what can't be fully built.
- **DRY** — every piece of knowledge has one authoritative representation; reuse rather than duplicate.
- **Latest stable dependencies** — verify the newest stable release against the registry before adding/bumping; no pre-releases without approval.
- **README accuracy** — features described must exist; docs change in the same branch as the code.
- **A published GitHub release per tag** — each release tag matches the `CHANGELOG.md` version, with descriptive notes referencing the relevant ADRs/specs.

**The `claims` / merge model.** Claims live on the dedicated unprotected `claims` branch, never on `main` (ADR-004); first-push-wins via git's atomic non-fast-forward rejection. Merges to `main` are **autonomous** once the required checks are green (`gh pr merge --auto --squash`, no required reviewers; ADR-005) — except paths owned in `.github/CODEOWNERS` (trust-bearing gate/tooling surfaces, ADR-019), which additionally require a human code-owner review. Never use admin bypass as a normal path. mathlib4 is pinned to release tags and never built from source; toolchain bumps only in dedicated PRs (ADR-002).

**The two CI gates that decide every PR — both must be green to merge:**

- **Gate A (soundness):** `lake build --wfail`, an axiom audit against the `{propext, Classical.choice, Quot.sound}` whitelist (now the declaration-scoped `nanoda` cross-check on leaf proofs, [ADR-097](docs/adrs/ADR-097-Phase3b-Nanoda-Replaces-Gate-A-Axiom-Audit.md)), leanchecker kernel replay, a regenerated statement-binding obligation ([ADR-011](docs/adrs/ADR-011-Statement-Binding-Gate.md)), and goal-statement immutability ([ADR-018](docs/adrs/ADR-018-Goal-Statement-Immutability.md)). Red-team-proven three times.
- **Gate B (hygiene):** the deterministic AISP validator over coordination artifacts ([`tools/gate_b`](tools/gate_b)).

By submitting a contribution you agree it is licensed under the project's [Apache-2.0 LICENSE](LICENSE).
