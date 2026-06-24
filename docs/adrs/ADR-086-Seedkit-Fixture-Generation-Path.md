# ADR-086: seedkit as a Documented Fixture-Generation Path Aligned to the Sourcing Paradigm

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-086 |
| **Initiative** | problem supply / corpus & attribution integrity |
| **Proposed By** | Chris Barlow (maintainer) |
| **Date** | 2026-06-23 |
| **Status** | Accepted |

## Context

The repo has **two** mechanisms that put new goals into the corpus, and only one
of them is documented.

**Path 1 — sourcing (canonical, documented).** ADR-060/062/067 plus the
`unsorry-goal-sourcing` skill and `swarm/sourcing.sh` define how new *open* goals
enter: a sourcer writes a three-file **triple** (`goals/<id>.lean` statement +
`sorry`, `goals/<id>.aisp` record `status≜open`/`sha≜∅`, `backlog/<id>.md`), the
goal passes the four-gate pipeline (absence → type-check → non-triviality battery
→ provable + adversarial skeptic), and a `chore(sourcing):` PR adds it for the
swarm to prove **later**. The contract is explicit — *"you create the problem,
you don't prove it"* (CONTRIBUTING.md, `SKILL.md`). Difficulty is self-tagged but
skill-enforced: the skeptic must reject anything closable by a single tactic
(`agents/skeptic.md`), the bar is *"no short one-tactic proof,"* and credit lands
on a **sourcing leaderboard** (`docs/metrics/sourcing-leaderboard.json`) weighted
by `difficulty_points` and `sourced_goals`, independent of who proves the goal.

**Path 2 — seedkit (real, merged, undocumented).** `tools/seedkit/` (contributed
by `chat-bit-01` in #2533, #5130, #5154) is a batch generator for parametric
integer identities across ~10 families (`gzmod`/`factdvd`/`residue` divisibility
& residue via kernel `decide` over a finite `ZMod`; `faulhaber`/`telescoping`/
`altgeom`/`oddsq`/`arith`/`shiftsq` closed forms via `induction; ring`). It is
**sound** — every statement is proven true before any file is written, and the
kit runs Gate A (`lake build --wfail`) and Gate B locally before pushing. But it
does not produce an *open* goal: `tools/seedkit/_artifact.py:write_artifacts`
mints a **5-file artifact** in one shot — the `goals/<id>.lean` statement, a goal
record born `status≜proved` with a real `sha` (`_artifact.py:80`), the prose, the
**finished proof** in `library/Unsorry/<Mod>.lean`, and the index record — then
`split_push.sh` pushes one `queued/prove/<id>` branch per goal for the scheduled
dispatcher to open and auto-merge. The goal is *born proved*; the prove arm never
touches it. ~1,475 merged proofs trace to these families.

Two specific frictions motivated this ADR.

**Attribution drift.** seedkit stamps its own provenance: `solver≜$SEEDKIT_SOLVER`
(default `anon`, `_artifact.py:69`), `agent≜seedkit`, `provider≜seedkit`,
`model≜template-zmod-decide`|`template-induction-ring` (`_artifact.py:48`,
`mkfiles*.py`). This is a parallel scheme — the rest of the system attributes via
the authenticated solver identity (ADR-007/ADR-023/ADR-029), and the honest
engine for these proofs is plain Lean (`provider≜lean; model≜decide` /
`model≜ring`), not a bespoke `seedkit` provider. The drift is not hypothetical:
`chat-bit-01`'s historical runs landed as `provider≜claude`, overstating LLM
involvement enough that the attribution-relabel sweep (CHANGELOG, ADR-079) had to
rewrite them to `provider≜lean; model≜decide` after the fact.

**Difficulty inflation.** Each family hard-codes a difficulty that the only check
(Gate B's 0–5 band, GB003) accepts blindly: `gzmod`/`factdvd`/`arith` = `3`,
`oddsq`/`telescoping`/`shiftsq` = `4`, **`altgeom`/`faulhaber` = `5`** — the top
tier the sourcing skill reserves for *"the most difficult problems"* — on goals
closed by a single fixed `decide` or `induction; ring`. Under the sourcing
rubric these are exactly the *"instance of `decide` on a concrete small case"*
the skeptic is written to reject; rated honestly they are difficulty 0–1. Because
sourcing credit is `difficulty_points`-weighted, a template farm self-tagging 3–5
inflates the very ledger the sourcing paradigm built to measure genuine hardness.

The maintainer directive: **keep seedkit** (it is sound and cheaply produces
reusable, kernel-verified library lemmas and regression fixtures), but **stop the
shadow-path divergence** — document it, and conform its attribution and
difficulty to the existing sourcing paradigm rather than perpetuate a parallel
bespoke scheme.

## WH(Y) Decision Statement

**In the context of** two unreconciled goal-origination paths — the documented
sourcing→prove pipeline (ADR-060/062/067: open-goal triples, skeptic-judged
difficulty, authenticated-solver provenance, a `difficulty_points`-weighted
sourcing leaderboard) and the undocumented `tools/seedkit/` (#2533/#5130/#5154),
a sound batch generator that mints goals **born `status≜proved`** straight to
`queued/prove/*` with a bespoke `solver≜anon`/`provider≜seedkit` provenance and
hard-coded difficulty 3–5 on template-closeable goals,

**facing** a README invariant that *"the path is the same — a worker takes an
open goal carrying a `sorry` and proves it"* which is silently false for seedkit;
seedkit being invisible across README, CONTRIBUTING, the Skills, and every
sourcing ADR; the sourcing skill stating path-local invariants as universal
(*"a fresh goal is always `status≜open`, `sha≜∅`"*; *"a real sha is only for
proved/archived"*); opposite difficulty bars applied to the same kind of object
(skeptic rejects one-tactic `decide`; seedkit self-stamps up to difficulty 5 on
exactly that); attribution drift that already required a post-hoc relabel sweep;
and a maintainer directive to legitimise seedkit while **conforming its
attribution and difficulty to the sourcing paradigm**, not a parallel ledger,

**we decided for** recognising seedkit as a **first-class but distinct
"fixture / library-growth" origination path** and bringing it into the canon:

1. **Document and disambiguate.** Name the two paths distinctly everywhere —
   *sourcing* = open goals for the swarm to prove; *fixtures (seedkit)* =
   batch-generated, deterministically-proved library lemmas. Add the fixture path
   as an explicit contribution mode in README and CONTRIBUTING; amend the README
   *"the path is the same"* invariant to admit the proved-on-arrival fixture
   path; and cross-reference the `unsorry-goal-sourcing` skill ↔ `tools/seedkit/`
   in both directions so an agent asked to *"batch-generate divisibility
   theorems"* routes to seedkit, not the four-gate sourcer.

2. **Conform attribution to the existing identity/provenance paradigm.** Replace
   seedkit's `solver≜anon` default with the authenticated solver identity the
   rest of the system uses (`UNSORRY_SOLVER`/gh, ADR-007/ADR-023/ADR-029) — no
   silent `anon` — and stamp **honest engine provenance at write-time**:
   `provider≜lean` for all families, `model≜decide` for the `ZMod`-`decide`
   families and `model≜ring` (induction + `ring`) for the closed-form families,
   retiring `provider≜seedkit`/`model≜template-*`. This makes the relabel sweep
   unnecessary for new records and matches how ADR-079 already classifies these
   proofs. `solver≜` contributor credit is preserved (consistent with the sweep's
   *"ranking unaffected"*).

3. **Conform difficulty to the sourcing rubric.** Replace the hard-coded
   per-family difficulty (3/4/5) with the honest value the skeptic's *"no short
   one-tactic proof"* bar assigns to a goal closed by a single `decide` or fixed
   `induction; ring` — **difficulty 1** — so the `difficulty_points` ledger
   reflects genuine hardness. A one-time difficulty backfill of the existing
   seedkit goal records is a **separable follow-up** (it churns the corpus and
   leaderboard and warrants its own change); this ADR fixes generation going
   forward and does **not** retroactively strip `solver≜` proof credit.

4. **Fix the path-local invariants and surface governance.** Correct the
   sourcing skill / `triple-format` lines that universalise `status≜open`/`sha≜∅`
   to note the fixture exception; and record the volume + auto-merge posture
   (seedkit lives outside `.github/CODEOWNERS`, so its output auto-merges with no
   code-owner review at batch volume, per ADR-005) as a conscious policy, with a
   visibility/throttle decision deferred to SPEC-086-A,

**and neglected** folding seedkit into the sourcing path (make it emit
`status≜open` goals for the swarm to prove) — rejected: it discards a proof the
generator already has in hand, floods the prover with trivially `decide`-closable
goals, and burns compute re-deriving deterministic results; quarantining seedkit
output into a separate library namespace excluded from headline metrics —
rejected per the maintainer's *conform-to-one-canon* direction over a parallel
ledger; retiring seedkit — rejected: it is sound and the cheapest source of
reusable kernel-verified library lemmas and regression fixtures; and keeping the
bespoke `solver≜anon` / `difficulty` 3–5 scheme and relying on the post-hoc
relabel sweep — rejected: that drift is precisely what required the sweep and is
the parallel-scheme divergence this ADR removes.

## What this changes (summary; full contract in SPEC-086-A)

- **seedkit code (`tools/seedkit/`).** `_artifact.py` solver default `anon` →
  authenticated identity; `provider`/`model` → honest Lean engine labels at
  write-time; per-family `difficulty=` (3/4/5) → 1. Docstrings and
  `tools/seedkit/README.md` updated to match; existing import-safety / Gate
  behaviour untouched. Test coverage (`tools/seedkit/tests/`) extended for the
  new provenance + difficulty (TDD).
- **Docs.** README: amend the *"path is the same"* invariant; add the fixture
  mode. CONTRIBUTING: add fixture generation to the ways to contribute, pointing
  at `tools/seedkit/README.md`, clearly marked *not sourcing*.
- **Skills.** `unsorry-goal-sourcing`: add a routing/cross-reference note to
  seedkit and fix the universalised `status≜open`/`sha≜∅` invariants;
  `tools/seedkit/README.md`: cross-reference the sourcing skill and its
  difficulty bar.
- **Governance.** SPEC-086-A decides whether the fixture namespace gets a
  per-run volume cap and/or CODEOWNERS coverage; minimum is logged visibility.

## Consequences

- **Positive.** One coherent canon: both growth vectors are named, documented,
  and discoverable; an agent or contributor can no longer be steered to the wrong
  path or be unaware the other exists.
- **Positive.** Attribution becomes honest at the source — authenticated solver,
  true Lean engine — so the relabel sweep is no longer needed for new seedkit
  records, and the leaderboard stops absorbing template proofs through a side
  channel.
- **Positive.** The `difficulty_points` ledger reflects real hardness; a template
  farm can no longer self-tag into the top difficulty tier.
- **Positive.** seedkit's value (cheap, sound, reusable library lemmas +
  regression fixtures) is retained — nothing is retired.
- **Negative.** Existing merged seedkit records keep their inflated difficulty and
  `provider≜seedkit`/relabelled provenance until the separable backfill runs;
  the corpus is briefly inconsistent (new records honest, old ones not).
- **Negative.** Lowering generated difficulty to 1 reduces the `difficulty_points`
  a fixture run earns — intended, but it visibly changes the standing of
  high-volume fixture contributors going forward.
- **Negative.** Touches `tools/seedkit/` (chat-bit-01's contribution); the change
  must be coordinated, not imposed silently, and lands as its own reviewed PR.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | seedkit fixture-path reconciliation spec | Specification | specs/SPEC-086-A-Seedkit-Fixture-Generation-Path.md |
| REF-2 | Contributor-Facing Goal-Sourcing Skill | Decision | ADR-060-Contributor-Goal-Sourcing-Skill.md |
| REF-3 | Swarm Goal-Sourcing Runner | Decision | ADR-062-Swarm-Goal-Sourcing-Runner.md |
| REF-4 | Demand-Driven Sourcing | Decision | ADR-067-Demand-Driven-Sourcing.md |
| REF-5 | Optional Proof Provenance and Leaderboard | Decision | ADR-023-Proof-Provenance-Leaderboard.md |
| REF-6 | Agent Identity and Budgets | Decision | ADR-007-Agent-Identity-and-Budgets.md |
| REF-7 | Autonomous Merge Policy | Decision | ADR-005-Autonomous-Merge-Policy.md |
| REF-8 | Attribution-relabel sweep (honest engine labels) | Decision | ADR-079 / CHANGELOG.md |
| REF-9 | seedkit tooling kit | Implementation | tools/seedkit/ (PRs #2533, #5130, #5154) |
| REF-10 | Sourcing leaderboard (difficulty-weighted) | Artifact | docs/metrics/sourcing-leaderboard.json |
| REF-11 | Maintainer directive (conform, don't parallel) | Issue | this change |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | Chris Barlow | 2026-06-23 |
| Accepted (implemented with SPEC-086-A in the same change) | Chris Barlow | 2026-06-23 |
