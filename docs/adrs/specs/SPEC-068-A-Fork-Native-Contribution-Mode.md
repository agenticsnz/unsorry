# SPEC-068-A: Fork-Native Contribution Mode

Implements: [ADR-068](../ADR-068-Fork-Native-Contribution-Mode.md) · Status: Proposed · Updated: 2026-06-17

This spec is the contract for **fork mode**: the path by which a contributor with
**no write access** to the canonical `agenticsnz/unsorry` can run
`./swarm/run.sh` and have the swarm prove open goals and submit them
automatically. It is the Phase-1, **claimless** realisation of the volunteer-scale
onramp; the lease substrate (SPEC-053-A) and identity/quota (ADR-054) are Phase 2
and out of scope here. Everything not restated here is unchanged from SPEC-007-A
(the agent loop) and SPEC-058-A (the governed `run.sh`).

## 1. Deliverables

1. **Fork mode in `swarm/agent.sh`** — detection, an `upstream` read remote,
   claimless proving with read-only dedup, and cross-repo PR submission.
2. **`swarm/run.sh` fork awareness** — run the governed prover in fork mode; do
   **not** start the queue dispatcher (a fork cannot dispatch upstream branches).
3. **An upstream auto-merge enabler workflow** (`.github/workflows/`) — arms
   auto-merge on admissible fork prove PRs (the piece a fork cannot self-arm).
4. **Docs** — a fork-contribution section in `CONTRIBUTING.md` and the
   `swarm/README.md` runner table.

The enabler workflow runs in the **upstream** repository; (1), (2), (4) run on the
fork. A deployment that only ever forks needs (1)/(2)/(4); the maintainer lands
(3) once upstream.

## 2. Fork-mode detection

Fork mode is entered when **any** of:

- `UNSORRY_FORK=1` or `--fork` is set (explicit override); or
- `gh api repos/{origin-owner}/{origin-repo}` reports `.fork == true` **and** its
  `.parent.full_name`/`.source.full_name` is the canonical `agenticsnz/unsorry`; or
- the authenticated user lacks push to the canonical upstream
  (`.permissions.push == false` on the upstream repo).

`UNSORRY_UPSTREAM` (default `agenticsnz/unsorry`) names the canonical repo. On
entry the harness ensures an `upstream` git remote pointing at it (read-only use).
Detection is **fail-closed**: if mode cannot be determined (e.g. `gh` unavailable),
the harness must not silently push to a repo it lacks access to — it errors with a
config message (exit 2) telling the user to pass `--fork` or grant access. The
canonical (write-access) path is unchanged when detection says "not a fork."

## 3. Read path

In fork mode, the swarm reads canonical state from `upstream`, not the fork's
possibly-stale `origin`:

- `git fetch upstream main` (ADR-059 retrying fetch) and select goals against the
  upstream `main` snapshot — the dedup set must reflect what the upstream has, not
  the fork.
- The fork's `origin/main` is only a push target's base; goal selection,
  proved-set, and open-PR checks all read `upstream`.

## 4. Claimless proving + read-only dedup (no `origin/claims`)

Fork mode performs **no** claim acquisition, release, or `origin/claims` push.
Coordination is merge-time, exactly as sourcing (ADR-060) and dispatch dedup
(ADR-064):

Before proving a selected goal `g`, run **read-only** checks against `upstream`
(no write, no token beyond read):

1. **Already proved?** `g` has a `library/index` entry on the freshly-fetched
   `upstream/main` → skip (reuse the existing proved-set logic, DRY).
2. **Open prove PR?** an open PR on the upstream titled `prove(g):` exists
   (`gh pr list --repo <upstream> --search '"prove(g)" in:title' --state open`) →
   skip.

Both checks are **best-effort** (a `git`/`gh` error degrades to "not deduped, go
ahead" — ADR-064's posture: selection must not depend on API health). To lower
collisions when several forks run concurrently, goal selection **may** shard by a
stable function of `UNSORRY_AGENT_ID` (advisory only; never a correctness input).
Duplicates that slip through are caught by the upstream kernel (a duplicate proof
is sound) and first-merge-wins (the loser closes as a conflict).

## 5. Submission — cross-repo fork→PR

On a locally-verified proof (`lake build --wfail` + axiom audit pass, unchanged):

1. Push the proof branch to the **fork** (`origin`), not upstream:
   `git push origin <branch>` where `<branch>` is the usual
   `prove/<goal>/<agent>-<hex>` shape.
2. Open the PR **against the upstream** from the fork head:
   `gh pr create --repo <upstream> --base main --head <fork-owner>:<branch>
   --title 'prove(<goal>): …' --body <provenance>`.
   The title obeys ADR-026; the body carries solver/provider/model provenance.
3. The fork does **not** arm auto-merge (it cannot). The PR waits for the upstream
   enabler (§6).

`UNSORRY_SUBMIT_MODE` is effectively `pr` in fork mode (queue mode is upstream-only
— a fork cannot push `queued/prove/*` upstream). The fork's own `run.sh` therefore
runs the prover **without** the dispatcher loop.

## 6. Upstream auto-merge enabler workflow

A new scheduled workflow in the **upstream** repo arms auto-merge on fork prove
PRs — the action a fork cannot perform:

- **Trigger:** `schedule` (cron, e.g. `*/15`) and/or `pull_request_target` on
  `opened`/`reopened` for PRs from forks; runs in upstream context.
- **Auth:** `REFRESH_TOKEN` (the secret the `queue-dispatcher` already uses).
  **Unset → report-only**, never a hard failure (mirror `queue-dispatcher.yml`).
- **Selection:** open PRs from forks whose title matches `prove(<goal>):`
  (ADR-026), that touch **no** CODEOWNERS path (proofs add only `library/Unsorry/*`
  + `library/index/*` + a `proof-runs/*` record — never gates/harness), and that
  need no human review (ADR-005). For each, `gh pr merge --auto --squash`.
- **Safety:** the enabler only *arms* auto-merge; GitHub still blocks the merge
  until Gate A + Gate B are green. The enabler never bypasses a gate, never uses
  admin merge, and skips any PR whose diff falls outside the proof allow-paths.
- **Governor parity:** respects the same open-prove-PR / Gate-A-in-flight caps as
  the dispatcher (ADR-058) so fork PRs do not flood CI.

This workflow is the only **new upstream** surface; it is CODEOWNERS-owned
(`/.github/`) and lands with a maintainer review.

> **Implemented:** `.github/workflows/fork-automerge-enabler.yml` (the scheduled
> arming job) + `tools/repo/fork_automerge.py` (the pure, unit-tested admissibility
> selector: cross-repo, `prove(...)` title, proof-allow-paths only, not already
> armed; fail-closed on an unseen diff). Governor parity is the per-run `--limit`.

## 7. Solver credit

Unchanged from the canonical path: `UNSORRY_SOLVER` (or `gh api user`) is embedded
as `⟦Π:Provenance⟧{solver≜…}` in the content-addressed `library/index` entry, which
travels in the PR and survives the merge. The leaderboard credits the fork user;
git-author fallback still applies. No claims branch is involved, so credit no
longer depends on a claim record.

## 8. Exit codes

Identical to `agent.sh` (SPEC-007-A): `0` ok/nothing-to-do · `1` cycle failure ·
`2` config (incl. undeterminable fork mode, missing `upstream`, unauthenticated
`gh`) · `3` infra (CLI/ fetch). `supervise.sh` wraps fork mode unchanged.

## 9. First-run Actions approval (external, documented)

GitHub requires a maintainer "Approve and run" on a **new** fork contributor's
**first** workflow run; it is one-time per contributor. This spec cannot remove it
(it is a platform policy). Requirements:

- Fork mode logs a clear one-line notice on the first submitted PR explaining the
  pending approval.
- `CONTRIBUTING.md` documents it and notes the maintainer lever (the repository's
  "Fork pull request workflows from outside collaborators" Actions setting) as a
  policy/ADR-054 decision, not a code change.

## 10. Quality bar (SPEC-007-A) + tests

- `shellcheck` / `bash -n` clean on the modified `agent.sh` / `run.sh`.
- Hermetic self-tests (temp dirs, injected `gh`/`git` stubs; no network) for the
  **pure** helpers: fork-mode detection (override / fork-of-canonical / no-push /
  not-a-fork / undeterminable→fail-closed), the cross-repo `--head <owner>:<branch>`
  assembly, and the claimless read-only dedup decision (proved / open-PR / neither).
- The enabler workflow: `actionlint` clean; a unit test for its PR-selection /
  allow-path filter (Python, under `tools/`), mirroring the dispatcher's tests.
- No change to Gate A/B; fork PRs are gated by the *existing* soundness/hygiene
  workflows (which already trigger on `pull_request`).

## 11. Acceptance criteria

A fork user with **no upstream write access**:

1. clones their fork, runs `./swarm/run.sh` (fork mode auto-detected);
2. the swarm selects an un-proved, un-PR'd upstream goal, proves and self-verifies
   it locally, pushes the branch to the **fork**, and opens a `prove(<goal>):` PR
   to the upstream;
3. after the one-time first-run approval, Gate A + Gate B re-verify on upstream
   runners and pass;
4. the enabler workflow arms auto-merge; the PR squash-merges with no human review;
5. the leaderboard credits the fork user as solver;
6. **no step performs an upstream write from the fork** (verified: no
   `origin/claims` push, no upstream branch push, no upstream PR-arming by the
   fork).

## 12. Out of scope (Phase 2 / deferred)

- The **lease substrate** (fork-writable claims) — SPEC-053-A; build only when
  measured duplicate-verifier waste justifies it.
- **Identity / quotas / reputation / Sybil + flood resistance** — ADR-054.
- Eliminating the first-run Actions approval (a GitHub platform policy).
- Multi-fork claim coordination beyond advisory selection sharding.
- A hosted dispatch service reaching into forks (forks surface work as PRs).
