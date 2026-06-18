# ADR-068: Fork-Native Contribution Mode

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-068 |
| **Initiative** | volunteer-scale orchestration / non-contributor onramp |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-17 |
| **Status** | Proposed |

## Context

A non-contributor — someone with no write access to the canonical
`agenticsnz/unsorry` — currently cannot run the swarm to *solve* problems and
land the results. Coordinated `--prove` pushes a claim to `origin/claims` as its
**third step**, before any proving (`swarm/agent.sh` `claim_goal()` → `git push
origin claims`), and later pushes proof branches and opens PRs through `origin`.
A fork has zero write access to those upstream refs, so the loop dies at the
claim push, indistinguishably from a normal claim collision. The only
fork-capable mode today is `--prove-local`, which deliberately performs no remote
operations and therefore submits nothing. CONTRIBUTING states this plainly: "From
a fork without that access, use `--prove-local`."

The maintainer's target experience is the opposite of that dead end: **fork the
repo, run `./swarm/run.sh`, and unsorry takes care of the rest** — the swarm
proves open goals and submits them automatically, with no special repository
access.

Two prior ADRs circle this but do not deliver it:

- **ADR-053** separates claim *semantics* from the git-branch substrate to relieve
  write *contention* at fleet scale. But the fork blocker is *access*, not
  contention: a fork cannot write `origin/claims` **at all**, and every backend
  enumerated in SPEC-053-A (single branch, sharded branches, lease API, signed
  log) is an *upstream-write* substrate. A contention fix does not make a fork
  able to claim.
- **ADR-054** adds identity, quotas, and reputation — the abuse controls a public
  volunteer model needs. It is real and necessary at scale, but it is heavy infra
  and is not a prerequisite for a *single* maintainer (or a handful of forks) to
  contribute safely today.

What *is* already in place is everything needed to make a fork's contribution
**safe and largely automatic** without either of those:

- **The kernel is the trust boundary.** Gate A (`lake build --wfail`, axiom
  audit, leanchecker replay) re-verifies every PR on upstream-hosted runners,
  including fork PRs (the gate workflows trigger on `pull_request`). A fork's
  proof is never trusted on the fork's word — it is re-checked. Untrusted fork
  compute is therefore already safe (ADR-052).
- **Claimless contribution is a proven pattern.** Sourcing (ADR-060) already
  contributes *from a fork today* using **no pre-claim + merge-time dedup** — the
  claims branch is "prove-only and fork-inaccessible," and a duplicate sourced
  goal "wastes only compute, never soundness."
- **Goal-level dedup already exists for proving.** ADR-064's dispatcher opens at
  most one prove PR per goal, skipping goals already proved on `main` or already
  carrying an open prove PR — read-only checks that need no write access.
- **Autonomous merge on gate-green, no human reviewer** (ADR-005), and a
  governor (ADR-058) + dedup (ADR-064) that already bound scarce Gate A capacity.

Two GitHub-platform frictions are irreducible from inside the repo and must be
named rather than hidden: a **new** fork contributor's **first** Actions run
requires a one-time maintainer "Approve and run" (GitHub's default defense for
public forks; one-time per contributor), and a fork user **cannot self-arm
auto-merge** on a cross-repo PR (no write to the upstream).

## WH(Y) Decision Statement

**In the context of** a fork-access blocker that confines non-contributors to
`--prove-local` (which submits nothing), a target UX of "fork → `run.sh` →
automatic," and an environment where the kernel (Gate A) is already the trust
boundary that re-verifies fork PRs, claimless+merge-time-dedup is already proven
for sourcing (ADR-060), goal-level dedup already exists for proving (ADR-064),
and merge is already autonomous on gate-green (ADR-005),

**facing** the facts that forks cannot push to `origin/claims` or to upstream
proof branches (fork-inaccessible); that the ADR-053 lease substrate would solve
*contention* but its backends are all upstream-write and it — with ADR-054
identity/quota — is heavy infrastructure not yet built; and two irreducible
GitHub frictions (a one-time maintainer approval of a new fork contributor's
first Actions run, and a fork's inability to self-arm auto-merge),

**we decided for** a **fork-native contribution mode**, auto-detected when
`origin` is a fork of the canonical upstream (or lacks push access), that:
**(a)** proves **claimless** — no `origin/claims` push; instead a *read-only*
pre-prove dedup against the upstream (skip a goal already proved per the
`library/index` marker on the upstream `main`, or already carrying an open prove
PR per `gh pr list`), reusing ADR-064's goal-level dedup and ADR-060's
merge-time-dedup model, with optional per-agent goal-selection sharding to lower
inter-fork collision; **(b)** submits via a **cross-repo fork→PR** — push the
locally-verified branch to the user's *own* fork (which they can write), then
`gh pr create --repo <upstream> --head <forkowner>:<branch>`, where Gate A/B
re-verify on upstream runners; **(c)** lands automatically via an **upstream
auto-merge enabler** — a scheduled workflow authenticated with `REFRESH_TOKEN`
(the secret the queue-dispatcher already holds) that arms `--auto --squash` on
admissible fork prove PRs (gate-green, title-valid, no CODEOWNERS path, no human
review required per ADR-005), since a fork cannot self-arm; and **(d)** preserves
solver credit via `UNSORRY_SOLVER`/`gh api user` embedded in the content-addressed
index entry, which survives the PR,

**and neglected** requiring a lease/claim for fork proving (rejected for Phase 1
— `origin/claims` is fork-inaccessible and no fork-writable lease exists yet; a
duplicate fork proof wastes only Gate A compute, never soundness — ADR-018
immutability plus the kernel make a duplicate harmless — so claimless + read-only
dedup is the cheap, shippable path, exactly the sourcing precedent); building the
ADR-053 fork-writable lease *first* (rejected as premature — a GitHub App or
append-only log plus auth/uptime/evidence-export and ADR-054 identity is large
infra to stand up *before any UX ships*; measured duplicate-verifier waste should
justify it); reusing the upstream queue-dispatcher to dispatch fork branches
(rejected — the dispatcher cannot reach into forks; forks must surface work as
their own cross-repo PRs); switching the soundness gates to `pull_request_target`
to dodge the first-run approval (rejected — running untrusted fork *head* code
with upstream secrets is exactly the attack `pull_request_target` invites; the
approval is GitHub's safe default, is one-time per contributor, and maps cleanly
to an ADR-054 `observer → trial` promotion); and treating a fork's local proof as
trusted (rejected — upstream kernel re-verification is non-negotiable; fork mode
never short-circuits Gate A),

**to achieve** the "fork → `run.sh` → automatic" non-contributor route to solve
problems continuously — built entirely on the existing verifier trust boundary
and dedup machinery, with **no new lease or identity infrastructure** — so that a
maintainer (and, at modest scale, other forks) can run the swarm against a fork
and have proofs re-verified and merged hands-off,

**accepting that** duplicate fork proofs consume scarce Gate A capacity (bounded
by the ADR-058 governor and ADR-064 dedup, and measured so Phase 2 leases can be
justified or declined on evidence); that a *new* fork contributor's first Actions
run needs one maintainer approval (a GitHub policy, documented, optionally
relaxed via the repository's outside-collaborator Actions setting — a maintainer
/ ADR-054 decision); that the upstream gains one new enabler workflow holding
`REFRESH_TOKEN` (the same trust surface as the existing dispatcher, degrading to
report-only when unset); and that broad, abuse-resistant rollout still waits on
ADR-054 quotas — Phase 1 is safe at modest fork counts because the kernel bounds
soundness and the governor bounds CI load, but Sybil/flood resistance is ADR-054's
job, not this ADR's.

## What fork mode does (summary; full contract in SPEC-068-A)

1. **Detect.** Auto-enter fork mode when `origin` is a fork of the canonical
   `agenticsnz/unsorry` (GitHub `.fork`/`.parent`) or the authenticated user
   lacks push to it; an explicit `--fork` / `UNSORRY_FORK=1` override forces it.
   Add an `upstream` remote for read-only fetch of `goals/` and `main`. Fail
   closed if mode cannot be determined.
2. **Prove claimless.** Select an open goal; **read-only** dedup against the
   upstream (already-proved? open prove PR?); prove and fully self-verify locally
   (`lake build --wfail` + axiom audit) — exactly as today, minus the claim.
3. **Submit cross-repo.** Push the verified branch to the fork; open a
   `prove(<goal>):` PR from `<forkowner>:<branch>` to the upstream. Gate A/B
   re-verify there.
4. **Land hands-off.** The upstream enabler workflow arms auto-merge on
   admissible fork prove PRs; gate-green → squash-merge → solver credited. The
   only human touch is the one-time first-run Actions approval per new fork user.

## Consequences

- **Positive.** Delivers the "fork → `run.sh` → automatic" UX with **no new lease
  or identity infrastructure** — only fork-mode plumbing in the runner plus one
  upstream enabler workflow.
- **Positive.** Soundness is untouched: the upstream kernel re-verifies every fork
  PR; a malicious or buggy fork cannot poison the library.
- **Positive.** Reuses proven patterns end-to-end (ADR-060 claimless, ADR-064
  dedup, ADR-005 auto-merge, ADR-058 governor), keeping the blast radius small.
- **Negative.** Claimless means duplicate fork proofs can each consume a Gate A
  run before first-merge-wins; the cost is verifier capacity, never soundness,
  and is bounded + measured to decide on Phase 2.
- **Negative.** A new fork contributor's first PR needs a one-time maintainer
  approval (GitHub policy); fully hands-off begins from the second PR.
- **Negative.** Abuse/Sybil resistance is out of scope here and waits on ADR-054;
  Phase 1 is appropriate for modest fork counts, not an open public flood.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Fork-native contribution mode spec | Specification | specs/SPEC-068-A-Fork-Native-Contribution-Mode.md |
| REF-2 | Volunteer-Scale Claim Substrate (Phase-2 lease) | Decision | ADR-053-Volunteer-Scale-Claim-Substrate.md |
| REF-3 | Volunteer-scale claim substrate contract | Specification | specs/SPEC-053-A-Volunteer-Scale-Claim-Substrate.md |
| REF-4 | Agent Identity, Quotas, and Reputation | Decision | ADR-054-Agent-Identity-Quotas-And-Reputation.md |
| REF-5 | Contributor-Facing Goal-Sourcing Skill (claimless precedent) | Decision | ADR-060-Contributor-Goal-Sourcing-Skill.md |
| REF-6 | Goal-Level Dispatch Deduplication | Decision | ADR-064-Goal-Level-Dispatch-Deduplication.md |
| REF-7 | Autonomous Merge Policy | Decision | ADR-005-Autonomous-Merge-Policy.md |
| REF-8 | Runner-Pool Segmentation and Verification Capacity (governor) | Decision | ADR-058-Runner-Pool-Segmentation-And-Verification-Capacity.md |
| REF-9 | Claims on a dedicated branch (first-push-wins) | Decision | ADR-004-Claims-Branch-First-Push-Wins.md |
| REF-10 | Verification Tiers and Auditability | Decision | ADR-052-Verification-Tiers-And-Auditability.md |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-17 |
