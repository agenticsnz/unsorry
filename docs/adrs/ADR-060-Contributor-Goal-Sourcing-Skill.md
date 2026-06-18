# ADR-060: Contributor-Facing Goal-Sourcing Skill

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-060 |
| **Initiative** | contributor scale / problem supply |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-16 |
| **Status** | Proposed |

## Context

Issue #400 asks to "make this process for generating new problems a claude skill
(using claude creator skill) based on unsorry project protocols ... open this up
to contributors to generate new problems as well and ensure that we are not
conflicting with each other," with the explicit steer to **move the goalposts —
make the problems harder and generate way more of them**. (The comment said
"proofs"; the maintainer clarified on #1533 that the intent is *generating new
problems to solve* — i.e. **sourcing new open goals**, not authoring proofs for
existing ones.)

The upstream sourcing pipeline already exists and has shipped 553 goals across
five Identity-Engine cycles (ADR-043, SPEC-043-A): ideate → absence-screen
(`tools.sourcing.check_absence`) → statement type-checks → non-triviality-screen
(`tools.sourcing.check_triviality`) → intended-proof compiles → adversarial
skeptic → write the goal **triple** (`goals/<slug>.lean` sorry-stub,
`goals/<slug>.aisp` record, `backlog/<slug>.md` entry) → Gate B → `chore(sourcing):`
PR ≤50 goals → auto-merge → announce on #81/#400. But it is driven by maintainer
agents with canonical write access, the triple is hand-authored, the difficulty
field is self-tagged and **gate-unenforced** (most shipped goals sit at difficulty
1–2), and there is **no contributor-facing entrypoint**.

Meanwhile the four existing skills (`unsorry-proof-authoring`,
`unsorry-gate-validation`, `unsorry-leaderboard-integration`,
`unsorry-swarm-operations`) all cover the *downstream* half — proving a goal that
already exists. None covers *sourcing*. `unsorry-proof-authoring` is scoped to
"adding, repairing, or reviewing Unsorry Lean proofs" and starts at an existing
`goals/<id>.aisp`; sourcing is the opposite end of the queue.

The relevant coordination substrate is only partly built: the claims branch
(ADR-004, first-push-wins) is **prove-only and fork-inaccessible**, and the
volunteer-scale claim substrate (ADR-053) and agent identity/quota/reputation
controls (ADR-054) are **Proposed, not built**. Gate B, however, runs on
GitHub-hosted `ubuntu-latest` via `pull_request` over `tools/sourcing/**` and
`goals/**` — so a sourcing-only PR (no proof) is fully Gate-B-checkable from a
fork without spending the trusted namespace verifier lane (ADR-049, ADR-058).

## WH(Y) Decision Statement

**In the context of** an existing, validated goal-sourcing pipeline that has no
contributor-facing entrypoint, a hand-authored triple step, a gate-unenforced
difficulty field, and external contributors arriving at much larger scale,

**facing** the need to open sourcing to fork contributors without (a) letting
them collide with each other or the swarm, (b) lowering the difficulty of the
problem supply, or (c) depending on coordination machinery (ADR-053/054) that is
not yet built,

**we decided for** a **new contributor-facing skill `unsorry-goal-sourcing`**,
authored with the `skill-creator` skill and following the convention the four
existing unsorry skills already use, that walks a contributor (or agent) through
the four-gate sourcing pipeline and the exact triple format; backed by a real
`tools/sourcing/gen_triples.py` that assembles and Gate-B-validates a triple from
a single candidate line; using **no pre-claim + merge-time dedup** as the
sourcing conflict model (Tier 0, works from a fork today), written against a thin
claim-interface seam so ADR-053 can back it later; enforcing a **maximum-difficulty
bar in the skill itself** (the difficulty field is gate-unenforced, so the skill
is the only enforcer — target difficulty ≥3 with at least one decomposition edge,
preferring substrate/olympiad/SOS-inequality families that survive the
triviality battery by design); sourcing **Phase-2 Euler-substrate** and **Phase-3
library-growth** targets **in parallel** (ADR-031); and adding a **sourcing
leaderboard** mode that credits contributors who source goals, independent of
proof credit,

**and neglected** extending `unsorry-proof-authoring` (rejected — sourcing and
proving are opposite ends of the queue with distinct roles, toolchains, and
conflict models; bundling bloats the skill and confuses triggering), pre-claiming
sourcing work on the claims branch (rejected — it is prove-only and
fork-inaccessible, and a duplicate sourced goal wastes only compute, never
soundness, so a claim is not worth the coupling), blocking the skill on ADR-053/054
(rejected — that stalls the contributor entrypoint behind unbuilt machinery;
instead default to no-pre-claim and leave a seam), gate-enforcing difficulty
(rejected for now — a robust hardness oracle does not exist; the skill enforces
the bar and the absence+non-triviality gates stay honest), adding
`nlinarith`/`positivity` to the triviality battery to raise the floor (rejected —
that supersedes the explicit ADR-035 design choice and would reclassify existing
goals; it needs its own ADR), and adding a structured `sourcer≜` field to the
goal record (rejected for the MVP — it is Gate-B schema churn; git add-author over
`goals/*.aisp`, the same mechanism the proof leaderboard already uses for
historical attribution, credits the sourcer with no schema change),

**to achieve** a self-serve, conflict-free way for contributors and agents to
generate **harder** problems and **many more** of them, grounded in the project
protocols, that works from a fork today and gets safer as ADR-053/054 land,

**accepting that** difficulty enforcement is skill-side and advisory rather than
gate-enforced (a low-difficulty sourcing PR is not rejected by CI — review and
the skill are the bar); that no-pre-claim has a race window between mine-time
dedup and merge (the cost is wasted contributor compute, never an unsound or
duplicated *merged* goal, because ADR-018 immutability plus the absence/triviality
gates catch survivors); that sourcing credit via git add-author is approximate
(earliest-add author, squash-merge author) until a structured field is justified;
and that opening sourcing to the world at "ludicrous" scale should still wait on
ADR-054 quota/abuse controls before the fork path is advertised broadly.

## What the skill enforces (summary; full contract in SPEC-060-A)

1. **Scope** — source only theorems already proven and plausibly **absent** from
   the pinned mathlib; never open conjectures (ADR-012).
2. **Four gates, in order** — absence (`check_absence`, exit 0 + record
   `mathlib_rev`) → statement type-checks (`lake build UnsorryGoals`) →
   non-triviality (`check_triviality`; admit verdicts `non-trivial`/`allowlisted`/
   `override` = exit 0; `trivial` = exit 1 reject; `probe-error` = exit 2 must be
   fixed, not admitted) → intended proof compiles (`lake env lean`) + adversarial
   skeptic.
3. **Difficulty bar** — target difficulty ≥3 with ≥1 decomposition edge; prefer
   hard families (Freek-#50 Euler substrate, olympiad/PutnamBench/miniF2F,
   multivariate SOS/field inequalities the battery does not close).
4. **Triple format** — exactly the SPEC-003-A schema for a *fresh* goal:
   `status≜open`, `sha≜∅`, `phase≜prove`; generated and validated by
   `gen_triples.py`.
5. **Conflict model** — `git fetch origin` + slug/statement dedup vs live
   `origin/main` before every batch; one theme per session; **no claims-branch
   push**; merge-time dedup is the backstop.
6. **PR discipline** — `chore(sourcing):` title (a valid Conventional-Commits
   type is what the gate requires; `(sourcing)` is the project convention the
   skill self-enforces), ≤50 goals per PR, no `docs/targets.md` regeneration
   (ADR-036), announce on #81/#400 after merge.

## Consequences

- **Positive.** A documented, conflict-free contributor entrypoint for *harder,
  more* problems; the hand-authored triple becomes a tested tool; sourcing finally
  earns leaderboard credit.
- **Positive.** Works from a fork today (Gate B on `ubuntu-latest`) without
  spending the trusted verifier lane.
- **Negative.** Difficulty stays advisory until a hardness oracle or an ADR-035
  amendment exists; the skill and review carry the bar.
- **Negative.** No-pre-claim wastes some contributor compute on raced duplicates.
- **Negative.** Broad external rollout still depends on ADR-054 quota controls.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Contributor goal-sourcing skill spec | Specification | specs/SPEC-060-A-Contributor-Goal-Sourcing-Skill.md |
| REF-2 | Backlog Sourcing | Decision | ADR-012-Backlog-Sourcing.md |
| REF-3 | Non-Trivial Theorem Enforcement | Decision | ADR-035-Non-Trivial-Theorem-Enforcement.md |
| REF-4 | Identity Engine | Decision | ADR-043-Identity-Engine.md |
| REF-5 | Goal Record Schema | Specification | specs/SPEC-003-A-Goal-Record-Schema.md |
| REF-6 | Proof Provenance Leaderboard | Specification | specs/SPEC-023-A-Proof-Provenance-Leaderboard.md |
| REF-7 | Freek-50 Platonic Solids Roadmap | Decision | ADR-031-Freek-50-Platonic-Solids-Roadmap.md |
| REF-8 | Volunteer-Scale Claim Substrate | Decision | ADR-053-Volunteer-Scale-Claim-Substrate.md |
| REF-9 | Agent Identity, Quotas, and Reputation | Decision | ADR-054-Agent-Identity-Quotas-And-Reputation.md |
| REF-10 | Next batch of theorems / move the goalposts | Issue | GitHub issue #400, tracking issue #1533 |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | unsorry maintainers | 2026-06-16 |
