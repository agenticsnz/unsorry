# ADR-087: Backfill Historical seedkit Records to Honest Provenance & Difficulty

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-087 |
| **Initiative** | corpus & attribution integrity |
| **Proposed By** | Chris Barlow (maintainer) |
| **Date** | 2026-06-23 |
| **Status** | Accepted |

## Context

[ADR-086](ADR-086-Seedkit-Fixture-Generation-Path.md) conformed `tools/seedkit`'s
attribution and difficulty to the sourcing paradigm **going forward** — honest
`provider≜lean` / `model≜decide`/`ring`, an authenticated solver, and difficulty
`1` — and explicitly deferred (§8) the records already merged before the change.
This ADR is that deferred follow-up.

The deferral left the corpus split. New fixtures are honest; the historical ones
are not:

- **~561 merged seedkit goal records** (`goals/*.aisp`) still carry inflated
  difficulty `2–5` (gzmod ~403, faulhaber ~158). The leaderboard sums each proof's
  goal difficulty into the solver's `difficulty_points` and score
  (`tools/leaderboard/generate.py`), so a fixture contributor's standing still
  reflects the old 3–5 self-tags. (Identification is by **proof provenance**, not
  goal-id family: the difficulty-`2–5` corpus also contains ~306 `gzmod-` goals
  proved by the **separate** `mac-158f` Python/sympy pipeline, plus genuinely
  sourced goals — both **out of scope** here; see Consequences.)
- **~158 index records** still carry a bespoke seedkit label: mostly
  `model≜template-induction-ring` under `provider≜claude` or `provider≜seedkit`,
  plus the `provider≜seedkit` `template-zmod-decide` records the existing sweep
  skipped. (The `claude`/`template-zmod-decide` records were already corrected to
  `provider≜lean; model≜decide` by that sweep.)

There is already a maintained, idempotent, self-healing mechanism for the
provenance half: `tools/repo/relabel_attribution.py` + `attribution-relabel.yml`
(ADR-079). Its `_RULES` table is keyed on `(agent, model-shape) → (provider,
model)` so it disambiguates the two engines that both used `template-*` labels —
`mac-158f` is genuinely `python/sympy`, `claude-web` (chat-bit-01) is `lean` — and
it never changes `solver≜` credit and scans active **and** archive index records.
But it deliberately (a) processes only `provider≜claude` records (skipping
`provider≜seedkit`), (b) has no induction-ring → `ring` mapping, and (c) does not
touch goal-record difficulty at all.

So closing the gap is mostly an *extension* of an existing, tested tool — plus a
new, parallel difficulty corrector for goal records. The one genuinely
consequential part is that correcting difficulty **retroactively lowers the
`difficulty_points` and score** of fixture contributors (chat-bit-01 most), which
is why ADR-086 §8 said this "warrants its own decision."

## WH(Y) Decision Statement

**In the context of** ADR-086 conforming seedkit going forward while leaving
~561 merged seedkit goal records at inflated difficulty `2–5` and ~158 index records on
bespoke `template`/`seedkit` labels, with the leaderboard still crediting fixture
contributors the inflated `difficulty_points`,

**facing** a corpus now split between honest new records and un-honest old ones;
an existing self-healing relabel sweep that covers only the `claude`
`template-zmod-decide` provenance case (excludes `provider≜seedkit`, has no
induction-ring mapping, and never touches difficulty); and the sensitivity that a
difficulty backfill **retroactively lowers** fixture contributors' score on a
public engagement surface,

**we decided for** a **one-time-but-idempotent backfill, implemented as an
extension of the existing attribution sweep**, that:

1. relabels every **seedkit-signature** index record to `provider≜lean` +
   `model≜decide`/`ring` — adding the `template-induction-ring → ring` mapping and
   processing `provider≜seedkit` as well as `provider≜claude` — across active and
   archive, keyed on the `agent` + `template`-model signature so genuine LLM
   proofs and `mac-158f`'s real `python/sympy` templates stay untouched;
2. corrects the **difficulty of every seedkit-origin goal record to `1`** (goals
   are never archived under `packages/`, so one pass over `goals/` fixes the
   `difficulty_points` of both active and archived proofs);
3. **never changes `solver≜` credit** (the correction is to honesty of engine +
   difficulty, not to who is credited); and
4. is **idempotent and self-healing** so it converges on the live, racing corpus
   and a re-run is a no-op once corrected,

**and neglected** leaving history as-is (rejected — it leaves the corpus and the
leaderboard permanently inconsistent with ADR-086, the very honesty gap ADR-086
set out to close); a one-shot migration script (rejected — the relabel sweep's
own history shows a one-shot cannot survive a corpus racing thousands of commits
an hour: PR #3218 "conflicted and was always incomplete" and had to be replaced by
the idempotent sweep, ADR-079); changing `solver≜` credit or removing fixture
proofs from the board (rejected — out of scope; the backfill corrects *labels and
difficulty*, deliberately ranking-neutral on the credit axis); and a
difficulty-only or provenance-only backfill (rejected — both dimensions were
inflated, so doing one leaves the corpus half-corrected).

## What this changes (summary; full contract in SPEC-087-A)

- **Provenance** — extend `tools/repo/relabel_attribution.py`: add
  `template-induction-ring → lean/ring` rows, relax the `provider≜claude`-only
  guard to also process `provider≜seedkit`, keeping agent-keyed disambiguation,
  idempotency, archive scope, and `solver≜` untouched.
- **Difficulty** — a new corrector (sibling function/CLI) that sets
  `difficulty≜1` on every seedkit-origin `goals/*.aisp` (identified by the same
  agent + template/engine signature on the goal's proof index record), idempotent.
- **Automation** — reuse `attribution-relabel.yml` (post-merge + hourly,
  `REFRESH_TOKEN`, `[skip ci]`, report-only if unset). Note: extending the commit
  scope to `goals/` may require editing that workflow, which is a `.github/`
  **CODEOWNERS** surface and so needs a code-owner-approved PR (the tool change
  itself, under `tools/repo/`, is not owned and auto-merges).
- **Tests** — extend `tools/repo/tests/test_relabel_attribution.py` for the new
  rules and the difficulty corrector (pure functions, idempotency cases).

## Consequences

- **Positive.** The corpus and leaderboard become consistent with ADR-086 — no
  split between honest new records and inflated old ones.
- **Positive.** Reuses a proven, idempotent, self-healing mechanism; converges on
  the live corpus; `solver≜` credit and ranking-by-credit are unaffected.
- **Positive.** Provenance stops overstating a bespoke `seedkit` engine and
  difficulty stops overstating hardness — both now match the honest going-forward
  labels.
- **Negative — the load-bearing one.** Fixture contributors' `difficulty_points`
  and score **drop retroactively** (chat-bit-01 most). This is the honest
  correction, but it visibly changes historical standings on a public board and
  must be a conscious, announced maintainer call — accepted by the maintainer
  (Status History) and announced in the changelog.
- **Negative.** Editing ~561 goal records + ~158 index records is a one-time
  settling churn; the goal-difficulty commit rides the existing
  `attribution-relabel.yml` `git add -A`, so **no CODEOWNERS workflow edit** is
  needed.
- **Discovered, out of scope.** The same triviality applies to ~306 `gzmod-`
  goals proved by the **separate** `mac-158f` Python/sympy pipeline (a different
  contributor, ohdearquant), which also self-tagged difficulty `3`. This backfill
  deliberately corrects **seedkit only** (the subject of ADR-086/087), leaving a
  cross-prover difficulty inconsistency for identical gzmod families. Extending
  the correction to `mac-158f` would lower another contributor's standings and so
  warrants its own decision — flagged as a follow-up, not silently bundled here.
- **Negative.** The difficulty corrector edits a *merged* goal record's metadata.
  ADR-018 immutability governs the *statement*, not difficulty, so this is
  permitted — but it sets a (documented, difficulty-only) precedent for
  retroactive metadata correction.

## References

| Reference ID | Title | Type | Location |
|--------------|-------|------|----------|
| REF-1 | Historical seedkit backfill spec | Specification | specs/SPEC-087-A-Backfill-Historical-Seedkit-Records.md |
| REF-2 | seedkit Fixture-Generation Path | Decision | ADR-086-Seedkit-Fixture-Generation-Path.md |
| REF-3 | Deterministic Solver Provider / relabel sweep | Decision | ADR-079-Deterministic-Solver-Provider.md |
| REF-4 | Optional Proof Provenance and Leaderboard | Decision | ADR-023-Proof-Provenance-Leaderboard.md |
| REF-5 | Archive policy | Decision | ADR-041 (library archiving) |
| REF-6 | Goal-Statement Immutability (statement only) | Decision | ADR-018-Goal-Statement-Immutability.md |
| REF-7 | Existing attribution sweep | Implementation | tools/repo/relabel_attribution.py + .github/workflows/attribution-relabel.yml |

## Status History

| Status | Approver | Date |
|--------|----------|------|
| Proposed | Chris Barlow | 2026-06-23 |
| Accepted (implemented — relabel-sweep extension + difficulty backfill) | Chris Barlow | 2026-06-23 |
