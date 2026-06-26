# ADR-095: Widen the goal `difficulty` band from 0–5 to 0–9

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-095 |
| **Initiative** | problem supply / corpus schema |
| **Proposed By** | maintainer (buy-in given; this PR is manually reviewed) |
| **Date** | 2026-06-24 |
| **Status** | Accepted |

## Context

`difficulty` is a goal-record field (`goals/<id>.aisp`) defined by **SPEC-003-A**
as *"integer 0–5 | 0 trivial … 5 research-grade."* It is a **self-tag**: ADR-035
records it as *"an advisory self-tag with no gate,"* and ADR-078 deliberately
**neglects** it as a scoring signal (the `difficulty_points` weighting is
farmable, so the board does not trust it). The only automated check is Gate B's
**GB003** enum-domain validation, which enforces the band.

The enforcement is encoded as a **single-character** check —
`tools/gate_b/validator.py`: `len(difficulty) != 1 or difficulty not in "012345"`
— so the ceiling is both a *value* bound (≤ 5) and an *encoding* bound (one
digit). The same 0–5 bound is duplicated in three other places: the sourcing
triple generator (`tools/sourcing/gen_triples.py`), the seedkit fixture writer
(`tools/seedkit/_artifact.py`), and the sourcing skill rubric/templates.

The sourcing mandate (ADR-060, `themes-and-difficulty.md`) is *"harder problems,
many more of them"* and the skill says *"aim high — the most difficult problems
are the best problems."* With the ceiling at 5, genuinely research-grade and
frontier goals all collapse onto a single top value, losing the granularity that
would let sourcers and routing distinguish *"hard"* from *"open-problem-adjacent."*
The maintainer asked to raise the ceiling.

This is **orthogonal to** the recent ADR-086/087/088 deflation work, which pushed
*template-closeable* goals **down** to difficulty 1 (correcting inflation at the
bottom). Raising the ceiling adds headroom at the **top** for goals that earn it;
it does not re-inflate templates and does not change scoring trust (the self-tag
remains advisory per ADR-078).

## WH(Y) Decision Statement

**In the context of** a `difficulty` self-tag bounded to a single digit 0–5 by
GB003 (SPEC-003-A), duplicated in the sourcing generator, the seedkit writer, and
the sourcing rubric, with a sourcing mandate to supply genuinely harder problems,

**facing** a top tier (5) that conflates every research-grade and frontier goal
into one value and offers no headroom above it, while a larger change (a two-digit
scale) would require re-architecting the single-character encoding every consumer
(gate, generators, visualiser, the `difficulty≜[2-5]` relabel regex, the
leaderboard) assumes,

**we decided for** widening the band to **0–9** — the largest range that keeps the
single-digit encoding (GB003 stays `len == 1`, the enum becomes `"0123456789"`) —
**preserving the 0–5 anchors unchanged** and adding **6 exceptional, 7–8 frontier,
9 open-problem-adjacent** on top. No existing record changes meaning or value
(0–5 is a strict subset of 0–9), so there is **no data migration**; existing
goals remain valid and render unchanged.

**accepting** that (a) 10+ remains rejected — a two-digit ceiling is explicitly
out of scope and would need the encoding change above; (b) raising the ceiling
does not make the self-tag trustworthy for scoring (ADR-078 still neglects it);
(c) the new 6–9 labels are advisory, judged by the sourcer under the same
*"no short one-tactic proof"* bar.

**and neglecting** (a) a two-digit/continuous difficulty scale — large blast
radius for marginal benefit while the tag is advisory; (b) gating difficulty
against a hardness oracle — ADR-078 §neglected establishes difficulty estimation
is as hard as the proof and farmable; (c) re-anchoring the existing 0–5 meanings —
rejected to keep already-tagged goals stable.

## Consequences

- **Functional change** is one line in `tools/gate_b/validator.py` (the GB003
  enum) plus the duplicated bound in `tools/sourcing/gen_triples.py` and
  `tools/seedkit/_artifact.py`.
- **Schema/rubric** updated: SPEC-003-A, SPEC-060-A, and the
  `unsorry-goal-sourcing` skill docs/templates now state 0–9.
- **Tests**: `tools/gate_b/tests/test_validator.py` gains GB003 cases asserting
  6–9 pass and 10 / non-digit are rejected; the sourcing generator test moves its
  out-of-range case from 7 to 10.
- **Review**: `tools/gate_b/` is code-owned (ADR-019), so this PR requires a human
  code-owner review and does **not** auto-merge on green gates.
