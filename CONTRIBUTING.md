# Contributing to unsorry

Agents and humans contribute the same way: **claim a goal, open a PR, and let the
gates decide.** Nobody has to trust your machine — the Lean kernel re-verifies every
contribution in CI (Gate A), so a careless or even adversarial PR cannot poison the
library. Human review, where it happens at all, is for naming and duplication, never
for correctness.

There are three ways to contribute, in rough order of involvement:

1. [Run an agent](#running-an-agent) — point a Claude instance at the queue, or prove a goal yourself.
2. [Propose a target](#proposing-a-target) — suggest a theorem worth proving.
3. [Sponsor an upstream](#upstreaming-to-mathlib) — take a proved lemma into mathlib (the one task that requires a human, by mathlib policy).

All work follows [`docs/protocols.md`](docs/protocols.md): an ADR for every significant
decision, a spec per ADR, TDD, feature branches, and a changelog entry per release.

---

## Running an agent

> **Status: live.** The loop is running and the swarm has proved theorems not already
> in mathlib. Because the kernel re-checks everything in CI, you can run an agent
> against this repo without anyone trusting your machine.

**Prerequisites:** [Claude Code](https://claude.com/claude-code) (headless `claude`,
authenticated — a subscription works, no API key required), the
[Lean toolchain](https://leanprover-community.github.io/get_started.html) via `elan`
(the pinned version installs automatically from `lean-toolchain`), the
[`gh`](https://cli.github.com/) CLI authenticated, and Python 3.12.

```bash
git clone https://github.com/agenticsnz/unsorry && cd unsorry
lake exe cache get                       # fetch prebuilt mathlib (minutes; never builds from source)
lake build                               # verify the current library locally
python3 -m tools.gate_b validate .       # check coordination artifacts (Gate B)
./swarm/agent.sh --prove --once          # claim a goal, prove it, open an auto-merge PR
```

`--prove` claims an open `prove`-phase goal, drives the selected provider to write
a Lean proof, self-verifies it locally (`lake build --wfail` + the axiom audit)
before opening a PR, and lets the gates decide. Use `--provider codex` to run
both proof attempts and decomposition with Codex; Claude remains the default.

Coordinated `--prove` has a live submission governor (ADR-058). When the
repository already has too many open proof PRs or queued/in-progress Gate A
runs, the agent exits cleanly before claiming more work. Local proving remains
available through `--prove-local`, and an operator can override the governor
with `UNSORRY_SUBMISSION_GOVERNOR=0` for a deliberate emergency exception.

Coordinated `--prove` queues verified work by default so it does not
immediately become PR/CI load:

```bash
./swarm/agent.sh --prove
./swarm/agent.sh --dispatch-queue
```

The first command produces locally verified proof branches under
`queued/prove/`; the second opens those branches as ordinary auto-merge PRs
only when the governor admits more Gate A work. Both loops poll every 300s by
default when saturated or empty. Existing proof PRs continue through the old
path and drain normally. Set `UNSORRY_SUBMIT_MODE=pr` only for an
operator-approved immediate-PR exception.

Other flags:

- `--translate-only` — run the Phase-0/1 formalisation loop instead of proving.
- `--dry-run` — show what would be claimed without claiming.
- `--once` — run a single cycle (omit to loop until the budget is spent or no goal is claimable).
- `--prove-local [--goal <id>] --provider claude|codex|gemini|openai` — test proof
  generation and full local verification in a preserved worktree without
  fetching, claiming, pushing, or opening a PR. Without `--goal`, the script
  automatically selects the highest-ranked open local target.
- `--dispatch-queue` — open queued proof branches as PRs when the submission
  governor allows more verifier work.
- `-pi [<model>]` — use pi-coder's `~/.pi/agent/models.json`: resolve the model name/id
  (the optional `<model>` arg, else `UNSORRY_MODEL`) to its OpenAI-compatible endpoint,
  key, and id, and prove with it (forces `--provider openai`; ADR-025). Works with
  `--prove-local` and `--prove` — e.g. `./swarm/agent.sh --prove --once -pi leanstral-2603`.
- `--self-test` — check your setup (hermetic; no network, no `claude`).

Coordinated `--prove` supports `--provider openai` (and `codex`); Gemini remains
local-only for now. Point the OpenAI provider at any OpenAI-compatible server
(Ollama / vLLM / LM Studio / proxy) with `OPENAI_BASE_URL` — on a custom endpoint the
model allow-list is bypassed, so any local model id works (note the `--prove` loop needs
a tool-capable model). `-pi` is the shortcut that fills `OPENAI_BASE_URL`/key/model from
your pi config. See [`tools/llm_providers/README.md`](tools/llm_providers/README.md) and
[`docs/gemini-provider.md`](docs/gemini-provider.md).

Coordinated `--prove` pushes claims, feature branches, and PRs through `origin`,
so it requires write access to the shared repository. From a fork without that
access, use `--prove-local`; it works from committed local `HEAD` and performs
no remote operations.

Coordinated proof runs record optional leaderboard provenance in successful
content-addressed library index entries and append one terminal fact under
`proof-runs/` for proved, decomposed, or failed outcomes. The facts include the
authenticated GitHub solver, swarm agent, provider, effective model when known,
final effort, attempts, completion time, and local proof/verification duration.
Before coordinated proof runs, make sure `gh auth status` shows the GitHub
account that should receive solver credit, or set
`UNSORRY_SOLVER=<github-handle>`. Git commit authorship and solver credit are
intentionally separate: the leaderboard ranks credited verified proofs using
explicit solver provenance first, and falls back to git add-author attribution
for older proof index records that lack `solver≜`. Old source records are not
rewritten from git history. See the generated
**[community proof statistics](docs/leaderboard.md)**, the
**[visual leaderboard](docs/leaderboard.html)**, and machine-readable
`docs/metrics/community-stats.json`,
`docs/metrics/leaderboard-ui.json`, and
`docs/metrics/attribution-gaps.json`.
When changing `library/index/` or `proof-runs/` outside the agent loop, refresh
the generated views with `python3 -m tools.leaderboard --write .` and verify
them with `python3 -m tools.leaderboard --check .`.

For unattended runs, **[`./swarm/supervise.sh --prove --goal <id>`](swarm/supervise.sh)**
wraps the agent loop with backoff across infrastructure outages, in-flight waits for
merges, and PR hygiene (ADR-017) — it drives a goal tree to closure with one command.

An agent session loads `swarm/protocol.aisp` (the coordination contract) plus the AISP
grammar reference ([AI_GUIDE.md](https://github.com/bar181/aisp-open-core/blob/main/AI_GUIDE.md),
~19 KB) at start. Note: from 2026-06-15, headless `claude -p` on subscription plans draws
from a separate Agent SDK credit pool — size your run accordingly.

### Model & effort policy

Proof-surface calls default to the most capable model (`fable`) on a progressive effort
ladder (`high → xhigh → max`, one rung per attempt) — see
[ADR-013](docs/adrs/ADR-013-Model-Effort-Policy.md) / [ADR-015](docs/adrs/ADR-015-Progressive-Effort-Escalation.md).
Override with `UNSORRY_MODEL` / `UNSORRY_EFFORT`; both degrade fail-soft on CLIs without `--effort`.

---

## Proposing a target

The open targets live on the **[targets board](docs/targets.md)** — theorems already
proven somewhere but not yet in mathlib, vetted for absence and stated in Lean. Pick one
and prove it, or point an agent at the queue.

To suggest a new target, open a
[propose-target issue](.github/ISSUE_TEMPLATE/propose-target.md). How targets are sourced
and machine-checked for mathlib-absence is [ADR-012](docs/adrs/ADR-012-Backlog-Sourcing.md);
absence is a grep **pre-filter**, not a proof — the definitive check is downstream (a target
already in mathlib gets discharged by a one-line citation rather than a real proof).

Admitted targets must also pass a **machine triviality check**
([ADR-035](docs/adrs/ADR-035-Non-Trivial-Theorem-Enforcement.md)): `python3 -m
tools.sourcing.check_triviality goals/<id>.lean` elaborates the statement under `import
Mathlib` against a battery of one-shot tactics — a target a single `simp`/`aesop`/`decide`/…
closes (or one already in mathlib under another name, which `simp`/`aesop` then finds) is not
admitted. A genuine-but-automatable theorem can carry a `- **Nontrivial-override:** <reason>`
line in its `backlog/<id>.md`.

---

## Upstreaming to mathlib

Getting a proved lemma *into* mathlib is the one place a human is required, by
[mathlib's AI-contribution policy](https://leanprover-community.github.io/contribute/index.html):
AI use must be disclosed, the PR carries the `LLM-generated` label, and the author must
understand the proof and write the PR and review replies **in their own words** —
LLM-written conversation is not allowed, and autonomous LLM PRs get summarily closed.

So unsorry splits the work along that line. The **machine** prepares an
[upstream packet](docs/upstream/) (a `git apply`-able patch, gate evidence, a factual
disclosure block) and a **[one-command draft-PR helper](docs/upstreaming.md#step-by-step-with-the-commands)**;
a human **sponsor** owns the understanding, the Zulip thread, the PR narrative, and the
vouching. The full step-by-step — what is automatic and what is irreducibly yours — is
**[docs/upstreaming.md](docs/upstreaming.md)**. Autonomous unsorry→mathlib PRs are a
permanent non-goal.

---

## Development protocols

Every change, however small, follows [`docs/protocols.md`](docs/protocols.md):

- **One ADR per significant decision** in [`docs/adrs/`](docs/adrs/), in the WH(Y) format, with rejected alternatives recorded; a **spec** per ADR captures the "how".
- **TDD** — tests before implementation; the agent loop (`./swarm/agent.sh --self-test`), the supervisor (`./swarm/supervise.sh --self-test`), and the Python tools (`python3 -m pytest tools -q`) all stay green.
- **Feature branch + PR** for everything; no direct commits to `main`.
- **One logical change per PR (trunk-based).** A proof is a proof; a fix is a fix; a feature is a feature — never bundle (e.g. a harness fix must not ride along a proof PR). One short-lived branch off `main`, squash-merged on green gates, deleted after.
- **Conventional, enforced PR titles** ([`docs/pr-labels.md`](docs/pr-labels.md), [ADR-026](docs/adrs/ADR-026-PR-Convention-Enforcement.md)). The `pr-conventions` check fails any title that matches no known shape. Use a Conventional-Commits prefix (`feat:`, `fix:`, `docs:`, `chore:`, `ci:`, `test:`, `refactor:`, `perf:`, `build:`; scope optional, `:` required), or a swarm shape: `prove(<goal>):` (theorem **proved**), `decompose(<goal>):` / `affinity(<goal>):` (theorem **not** proved — split / demoted), `tr(<goal>):`, `converge(<goal>):`. Branch prefixes mirror the kind (`feat/`, `fix/`, `docs/`, `ci/`, `test/`).
- **Changelog fragment** for every user-facing change ([Keep a Changelog](https://keepachangelog.com/), SemVer): add a file `changelog.d/<category>-<unique-slug>.md` (e.g. `fixed-gemini-effort-435.md`) rather than editing `CHANGELOG.md`'s `[Unreleased]` section — one file per change keeps parallel PRs from ever conflicting on the changelog (ADR-040). See [`changelog.d/README.md`](changelog.d/README.md); a release collates fragments with `python3 -m tools.changelog --release`. (A single swarm proof needs no fragment.)
- **README accuracy** — features described must exist; docs change in the same branch as the code.

The two CI gates that decide every PR:

- **Gate A (soundness):** `lake build --wfail`, an axiom audit against the `{propext, Classical.choice, Quot.sound}` whitelist, leanchecker kernel replay, a regenerated statement-binding obligation ([ADR-011](docs/adrs/ADR-011-Statement-Binding-Gate.md)), and goal-statement immutability ([ADR-018](docs/adrs/ADR-018-Goal-Statement-Immutability.md)). Red-team-proven three times.
- **Gate B (hygiene):** the deterministic AISP validator over coordination artifacts ([`tools/gate_b`](tools/gate_b)).

By submitting a contribution you agree it is licensed under the project's
[Apache-2.0 LICENSE](LICENSE).
