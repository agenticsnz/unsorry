# Sourcing from a fork (the contributor path)

You do **not** need write access to the canonical repo to source goals. A
sourcing-only PR (no proof) is fully checkable from a fork, because Gate B runs on
GitHub-hosted `ubuntu-latest` via `pull_request` over `tools/sourcing/**` and
`goals/**` — it needs **no project secrets and no trusted namespace verifier lane**
(ADR-049, ADR-058). Gate A (the credentialed Lean verifier) is the acceptance gate
for *proofs*, not for sourcing.

## Prerequisites

- A full local checkout with `lake exe cache get` (the multi-GB mathlib **binary**
  cache — never build mathlib from source; ADR-002). This is a real onboarding
  cost; budget for it. The toolchain installs from `lean-toolchain` via elan.
- `gh auth status` authenticated as **your** account (for sourcing credit), or set
  `UNSORRY_SOLVER=<your-github-handle>`.

## Flow

1. Fork `agenticsnz/unsorry`; `git fetch origin`; branch off fresh `origin/main`.
2. Pick (or propose) **one theme**; run the four gates (sourcing-pipeline.md).
3. Stage survivors in `backlog/candidates/<theme>.md`, or promote to triples with
   `gen_triples.py --validate`.
4. `python3 -m tools.gate_b validate .` once per batch as a barrier.
5. Open a fork PR titled `chore(sourcing): …`, ≤50 goals.
6. **First-time fork PRs need a maintainer "Approve and run"** click before Actions
   run — but once approved, Gate B validates your contribution automatically (no
   secrets needed). After that the PR auto-merges on green like any other.

## Provable-compile on a fork

Running gate 4's `lake env lean` provable-compile locally needs the mathlib cache.
If you cannot pay that cost, you may **defer type-checking to CI** — Gate B fails a
non-compiling `.lean`, so a bad statement is caught — but deferring lowers
candidate quality (you ship statements you have not seen elaborate). Prefer running
gates 2 and 4 locally when you can.

## Concurrency-safe writes

When the swarm is concurrently active, the shared `.git` gets GC'd/worktree-churned
and local `git add`/commit can hit `unable to read tree`. Write the triple via the
**GitHub git API** tree path instead — `createTree` (inline file content) →
`createCommit` → update ref — which is immune to local checkout churn. From a clean
fork checkout with no concurrent swarm, ordinary `git add` is fine.

## What is NOT available to a fork (by design)

- The **claims branch** (ADR-004) is prove-only and fork-inaccessible. Sourcing has
  **no pre-claim** — rely on mine-time + merge-time dedup (see SKILL.md).
- `agent.sh` claim/push/merge assumes canonical write access — never invoke it from
  a fork for sourcing.
- The volunteer-scale claim substrate and identity/quota controls (ADR-053/054) are
  **Proposed, not built**. Until they land, broad external rollout is gated; the
  skill works today for invited contributors and the maintainer swarm.

## Credit

Sourcing earns its own leaderboard (`python3 -m tools.leaderboard --sourcing`),
attributed by git add-author over `goals/*.aisp` and mapped through
`docs/metrics/contributor-aliases.json`. It is independent of proof credit — you
can rank on both. Authenticate as yourself (above) so the credit lands on your
handle.
