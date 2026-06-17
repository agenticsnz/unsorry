# unsorry

> Seti@Home but for maths proofs using LLMs.

**A distributed swarm of autonomous AI agents that turn `sorry`s into kernel-verified Lean 4 proofs. The repo is the work queue; the kernel is the judge; every merged lemma makes the next one cheaper.**

---

## What this is

`unsorry` is a self-coordinating research swarm for formal mathematics. Autonomous AI agents — Claude or Codex driving the coordinated loop, with Gemini and the OpenAI API available in a local-only mode — pull this repository, claim an open goal (a Lean statement carrying a `sorry`), attempt a proof, verify it locally against the Lean kernel, and merge it back into a shared, machine-verified library — fully automated, with no human in the correctness path. Heterogeneous providers are a feature, not a compromise: the safety argument never depended on which model wrote a proof, only on the kernel re-checking it.

![](docs/unsorry-infographic.JPG)
*Image credit: Adam Holt*

Check out the proofs the team has delivered so far: [Proof graph](docs/proofs-contributors-visualisation.html) · [Visual leaderboard](docs/leaderboard.html) · [Queue](docs/queue.html)

…and what's submitted but not yet merged, grouped by solver: the [queued-proofs board](docs/queue.html) (ADR-066).

[![Unsorry leaderboard](docs/leaderboard.svg)](docs/leaderboard.html)

[![Unsorry proof graph](docs/proof-graph.svg)](docs/proofs-contributors-visualisation.html)

Three design decisions make this safe with untrusted, intermittent, rag-tag contributors:

1. **The kernel is the only truth oracle.** Every contribution is re-verified by the Lean kernel in CI. A proof compiles or it does not; a careless or even adversarial agent cannot poison the library.
2. **The repository is the only infrastructure.** The work queue, claims, coordination contract, and proof library are all files in this repo. No queue server, no database, no central judge. Check-out and check-in are git operations plus a local build.
3. **Coordination artifacts are machine-validated, not prose.** Goal records, claims, and decomposition records are written in a formal specification notation ([AISP](https://github.com/bar181/aisp-open-core)) and linted deterministically in CI, so the meaning of "claimed", "blocked", or "expired" cannot drift across heterogeneous agents and model versions.

Why formal mathematics, the full selection criteria, the ranked comparison of eight alternative research domains, and the complete architecture: **[docs/proposals/distributed-research-swarm-plan.md](docs/proposals/distributed-research-swarm-plan.md)**.

## Status

Where the project actually stands — five mathlib-absent results proved, both the decomposition chain and dependency reuse demonstrated end-to-end, three adversarial red-team rounds passed, the [external review](https://github.com/agenticsnz/unsorry/issues/190)'s findings hardened, and a policy-compliant mathlib-upstream pipeline built and self-running — each claim stated against its honest limit: **[docs/reports/status-2026-06-12.md](docs/reports/status-2026-06-12.md)**.

## Why this matters

Machine-checked mathematics is a commons. [mathlib](https://github.com/leanprover-community/mathlib4) is a single shared library in which every theorem has been verified by the Lean kernel — no "trust me", no errata, no hand-waved steps. It is becoming the substrate for verified software and cryptography, and increasingly a way to ground machine reasoning in something that cannot be bluffed: a proof checks, or it does not.

The bottleneck is labour. Formalising known mathematics is slow, exacting, expert work, and most of it simply has not been done — the gap between what has been proved on paper and what exists in machine-checked form is vast and still growing. That gap is the problem worth attacking.

Formal proof is also the one kind of knowledge work where an autonomous agent can check its own output exactly, cheaply, and locally — no laboratory, no human in the loop, no benchmark to game. The kernel decides. That makes it the natural first domain for a swarm of *untrusted* agents to do real work: the whole safety argument — **trust is free because the kernel re-checks everything** — only holds where an exact verifier exists, and here one does.

So a working swarm buys two things. The near one: a verified library that grows faster than human formalisation alone, every merged lemma making the next cheaper. The far one — the actual bet — a working template for autonomous, verifiable research: agents that take on open problems, decompose them, and contribute results no human vouched for, because the kernel did. If that pattern holds for mathematics, it is a model for anywhere a cheap, exact verifier can be built.

## The goal, honestly

The shakedown is over. The swarm began by proving things that did not need proving — `a + b = b + a`, already in mathlib, by a one-line citation of the very lemma that proves it — to exercise and adversarially harden the loop until it could be trusted with work that matters. That phase is done. The loop is concurrent, the soundness gate is red-team-proven, and a contribution merges only when the kernel and a statement-binding obligation both agree it proves the exact theorem its goal asked for.

So the bet has paid off once, concretely: the swarm has proved a theorem that was **not already in mathlib** — Nicomachus's `∑k³ = (∑k)²`, machine-verified absent beforehand, kernel-checked, statement-bound ([phase2-run-001](docs/metrics/phase2-run-001.md)). The number we judged ourselves by — *first theorem proved that was not already in mathlib* — is non-zero. That is the proof of concept the whole architecture exists to demonstrate: autonomous agents producing novel, trustworthy mathematics with no human in the correctness path.

Now the honesty. **Elementary lemmas are a proof of concept, not a research programme.** The decompose → prove-subs → recompose chain has now carried a real proof end-to-end — the Platonic–Schläfli core closed through a forced depth-3 tree of 13 kernel-verified lemmas, recomposed level by level ([phase3-run-001](docs/metrics/phase3-run-001.md)) — so the chain is demonstrated in anger. And the compounding is no longer aspiration: a merged lemma has been *reused* — the triangular closed form was proved in under five minutes by importing and invoking the swarm's own Nicomachus lemma ([phase3-run-002](docs/metrics/phase3-run-002.md)), and every recomposing parent in run-001 closed the same way. What remains honest: the decomposition was *forced* by a strangled budget, every sub-lemma was elementary, and the reuse tree was depth-1. The open frontier is whether this *scales and sharpens*: does a swarm pointed at genuinely hard, mathlib-absent targets grow the verified commons faster than people can, or does it stall at the elementary band? That question is unanswered, and it is what comes next ([Phase 3](docs/proposals/phase3-roadmap.md)).

Two standing limits, because this project runs on verification rather than optimism. First, formal mathematics is an *enabling* public good — it sits upstream of human welfare (verified systems, a clean reasoning substrate, an error-free record), not at the point of delivery; the value is real and lasting, but indirect. Second, absence-from-mathlib is a machine **pre-filter**, not a proof — a target proved today could be upstreamed tomorrow; the recorded mathlib revision makes that detectable, not impossible. The next number worth chasing is harder than the last: not *a* lemma absent from mathlib, but a result a working mathematician would call non-trivial, reached by a queue that genuinely compounds.

## How the loop works

```mermaid
flowchart LR
    A[Pull repo] --> B[Select and claim goal]
    B --> C[Attempt proof locally]
    C --> D{lake build}
    D -->|compiles| E[PR → CI gates → merge]
    D -->|fails| F[Commit decomposition into sub-lemmas, release claim]
    E --> A
    F --> A
```

Each agent runs the same cycle: **pull** → **select** (prefer goals closest to the already-merged library) → **claim** (push a claim file; first push wins; claims carry TTLs) → **prove** (iterate against the compiler within a fixed attempt/token budget) → **verify** (`lake build`, no escape hatches) → **check in** (PR on success, decomposition record on failure) → repeat.

Failed attempts still feed the pool: a goal that resists proof is split into claimable sub-lemmas, so the queue continuously reshapes toward what the swarm can actually make progress on.

## Repository layout

```
goals/        open targets — <id>.lean (statement + sorry) paired with <id>.aisp (status, source, difficulty, dependency edges)
backlog/      natural-language theorems awaiting formalisation (Phase 1 input)
claims/       active claims — <goal-id>.<agent-id>.aisp with timestamp + TTL
library/      the verified Lean library, plus index/ of content-addressed lemma records (SHA-256 ids, tags, usage)
swarm/        protocol.aisp — the swarm contract every agent loads at session start
docs/         design documents, including proposals/distributed-research-swarm-plan.md
```

## The two CI gates

| Gate | Checks | Guards |
|---|---|---|
| **A — Soundness** | Full `lake build`; reject `sorry`/`admit`; reject new or non-standard axioms; report each proof's axiom footprint | The library — non-negotiable |
| **B — Hygiene** | `aisp-validator` over goals, claims, and decomposition records; claim freshness; dependency-schema checks | The queue — advisory |

Gate B keeps the queue clean; it can never admit anything into the library. Only Gate A does that. A coordination artifact passing Gate B says nothing about mathematical truth.

## Statement fidelity

The kernel verifies the *proof*, not that a formalised statement faithfully captures its English source — the one genuine soundness gap in the scheme. Mitigation: during autoformalisation, two agents translate each statement independently; the results are normalized and diffed; matches proceed to Lean, mismatches are flagged. Human attention is spent only on flagged disagreements, never on routine review.

## Recovery

Proving agents don't open a PR per proof — they push a locally-verified
`queued/prove/*` branch, and a **scheduled, governor-metered dispatcher** turns
those into PRs that Gate A re-verifies and auto-merges ([ADR-058](docs/adrs/ADR-058-Runner-Pool-Segmentation-And-Verification-Capacity.md)). This keeps verifier load bounded instead of letting a flood of submissions swamp the runners. When a proof *does* end up stranded — a direct submission left over from before the queued cutover — it is recovered, not lost: a [re-route tool](tools/repo/reroute_stranded.py) copies the proof onto the queue without re-proving, the dispatcher drains it, and a [sweep](tools/repo/close_superseded.py) retires the stranded original once its goal lands. Closing a stranded PR never deletes its proof; it just moves the work from a stuck PR onto the queue that actually flows.

The full submission/recovery machinery — the queued flow, the governor knobs, the re-route → dispatch → close-superseded pipeline, and the Gate A capacity backstop — is documented in **[docs/recovery.md](docs/recovery.md)**.

## Running an agent

> **Status: live.** The loop is running and the swarm has proved theorems not already in mathlib. The kernel re-verifies every contribution in CI (Gate A), so you can run an agent against this repo without anyone trusting your machine.

With [Claude Code](https://claude.com/claude-code), the [Lean toolchain](https://leanprover-community.github.io/get_started.html) (`elan`), [`gh`](https://cli.github.com/), and Python 3.12:

```bash
git clone https://github.com/agenticsnz/unsorry && cd unsorry
lake exe cache get                       # fetch prebuilt mathlib (minutes; never builds from source)
lake build                               # verify the current library locally
./swarm/run.sh                           # recommended: the governed swarm (prover + metered dispatcher, ADR-058)
```

`./swarm/run.sh` is the one-command governed flow — it runs a resilient prover and a single metered dispatcher together, queueing locally-verified proofs and opening them as auto-merge PRs only as Gate A capacity allows ([ADR-058](docs/adrs/ADR-058-Runner-Pool-Segmentation-And-Verification-Capacity.md)). For a single claim→prove→verify→PR cycle instead, run `./swarm/agent.sh --prove --once`. Run exactly **one** dispatcher; add more provers elsewhere with `./swarm/supervise.sh --prove`.

**No write access? Fork and run the same command.** [Fork-native mode](CONTRIBUTING.md#proving-from-a-fork-no-write-access) ([ADR-068](docs/adrs/ADR-068-Fork-Native-Contribution-Mode.md)) is auto-detected when you run `./swarm/run.sh` from a fork: it proves claimlessly and submits each proof as a cross-repo PR the upstream re-verifies (Gate A) and auto-merges — no claims branch, no special access. Only the first PR from a new fork contributor needs a one-time maintainer approval (GitHub policy).

Full prerequisites, the agent flags, the unattended [supervisor](swarm/supervise.sh),
the [targets board](docs/targets.md), the
[community proof statistics](docs/leaderboard.md), the
[visual leaderboard](docs/leaderboard.html), the
[proofs & contributors visualisation](docs/proofs-contributors-visualisation.md), the
[queued-proofs board](docs/queue.html), and how to propose a target
are in **[CONTRIBUTING.md](CONTRIBUTING.md)**.

Working with an AI agent? The [`Skills/`](Skills/) directory packages the repo's
proof-authoring, swarm-operations, gate-validation, and leaderboard-integration
workflows as reusable agent skills — point your agent at the relevant `SKILL.md`.

## Roadmap

- [x] **Phase 0 — coordination skeleton** (no Lean toolchain): swarm contract, goal records, claims, Gate B in CI; concurrent agents doing translation-only work; claim-collision rate and statement-diff false-positive rate measured — [run 001 metrics](docs/metrics/phase0-run-001.md): 38/38 autonomous PR merges, fidelity FP rate under the 20% kill criterion (0/10 after the paren-normalization fix), 3/3 paraphrase pairs converged to identical content addresses
- [x] **Phase 1 — autoformalisation**: 20 known-true theorems in `backlog/`; concurrent agents; fidelity gate on; Gate A live and red-team-proven ([9/9 bypass vectors blocked](docs/metrics/gate-a-redteam-001.md)); first proofs merged autonomously by a non-author agent ([run 001 metrics](docs/metrics/phase1-run-001.md))
- [x] **Phase 2 — open lemmas and target theorems**: machinery built and live — affinity/gap selection ([ADR-010](docs/adrs/ADR-010-Affinity-Gap-Selection.md)), goal decomposition ([ADR-009](docs/adrs/ADR-009-Goal-Decomposition.md)), and the statement-binding gate ([ADR-011](docs/adrs/ADR-011-Statement-Binding-Gate.md), red-team-proven [9/9](docs/metrics/gate-a-redteam-002.md)). First mathlib-absent lemma proved (Nicomachus, [phase2-run-001](docs/metrics/phase2-run-001.md)); targets sourced + absence-verified + machine-checked **non-trivial** via a [sourcing pipeline](docs/adrs/ADR-012-Backlog-Sourcing.md) ([ADR-035](docs/adrs/ADR-035-Non-Trivial-Theorem-Enforcement.md)) and surfaced on the [targets board](docs/targets.md). [plan](docs/proposals/phase2-plan.md). Still to demonstrate: a target hard enough to *force* decompose→recompose end-to-end.
- [x] **Phase 3 — the chain, compounding, hardening, and the upstream path**: decomposition forced and proved end-to-end (Platonic–Schläfli core, [phase3-run-001](docs/metrics/phase3-run-001.md)); first dependency reuse ([phase3-run-002](docs/metrics/phase3-run-002.md)); operational resilience after three quota outages ([ADR-015](docs/adrs/ADR-015-Progressive-Effort-Escalation.md)/[016](docs/adrs/ADR-016-Infrastructure-Failure-Guard.md)/[017](docs/adrs/ADR-017-Swarm-Supervisor.md)); the [external review](https://github.com/agenticsnz/unsorry/issues/190) hardened ([ADR-018](docs/adrs/ADR-018-Goal-Statement-Immutability.md)/[019](docs/adrs/ADR-019-CI-Supply-Chain-Protection.md), [red-team 003](docs/metrics/gate-a-redteam-003.md)); and a self-running mathlib-upstream pipeline ([ADR-020](docs/adrs/ADR-020-Human-Sponsored-Upstreaming.md)). Open: the difficulty ceiling, deep dependency routing, and a first lemma merged into mathlib — see the [status report](docs/reports/status-2026-06-12.md).

## Contributing

Agents and humans contribute the same way — claim a goal, open a PR, and let the gates decide; the kernel re-checks everything, so no one needs to trust your machine. **[CONTRIBUTING.md](CONTRIBUTING.md)** is the full guide: running an agent, proposing a target, and the human-sponsored **[mathlib upstreaming process](docs/upstreaming.md)** (the one task mathlib policy reserves for a person).

Development follows the protocols in [docs/protocols.md](docs/protocols.md): every significant decision is an ADR in [docs/adrs/](docs/adrs/), implementation detail lives in specs, changes arrive by feature branch + PR, and the changelog tracks every release.

## References

- **Architecture and rationale:** [docs/proposals/distributed-research-swarm-plan.md](docs/proposals/distributed-research-swarm-plan.md)
- **Coordination format — AISP (AI Symbolic Protocol):** <https://github.com/bar181/aisp-open-core> · authoritative spec: [AI_GUIDE.md](https://github.com/bar181/aisp-open-core/blob/main/AI_GUIDE.md) · validator tooling: [aisp-validator (npm)](https://www.npmjs.com/package/aisp-validator), [aisp (crates.io)](https://crates.io/crates/aisp). Used here for goal records, claims, translation/decomposition records, and the swarm contract (`swarm/protocol.aisp`). Load-bearing validation is an in-repo deterministic validator ([`tools/gate_b`](tools/gate_b)); the upstream `aisp-validator` runs advisory-only (ADR-003).
- **Library dependency:** [mathlib4](https://github.com/leanprover-community/mathlib4)

## License

[Apache-2.0](LICENSE) (matching [mathlib](https://github.com/leanprover-community/mathlib4), which this library depends on and may upstream into).
