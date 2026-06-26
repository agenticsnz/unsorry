# ADR-099: Re-attribute Agent-Owned Pipeline Solver to the Pipeline Owner

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-099 |
| **Initiative** | corpus & attribution integrity |
| **Proposed By** | Chris Barlow (maintainer) |
| **Date** | 2026-06-26 |
| **Status** | Accepted |

## Context

[ADR-079](ADR-079-Deterministic-Solver-Provider.md)/[ADR-088](ADR-088-Extend-Difficulty-Backfill-To-Mac158f.md)
corrected the *provider/model* and *difficulty* of ohdearquant's `mac-158f`
deterministic Python/sympy template pipeline, but **deliberately left `solver≜`
untouched** ("ranking *by credit* is unaffected; only difficulty-weighted points
move").

Auditing the contributor model breakdown surfaced a `solver≜` defect that
assumption masks. Of the **2,033** `agent≜mac-158f` index records, 1,896 credit
`solver≜ohdearquant` (the pipeline's owner) but **72 credit `cgbarlow` and 65
credit `perttu`** — and another 117 across `proof-runs/` — **254 records total**.
These are not independent work: they are the same pipeline's output (identical
`gpow`/`gbinom` template families, all difficulty 1), **landed via dispatched PRs
opened by those contributors** (the merge commits read "…`by mac-158f`"). The
proof-submission path stamped `solver≜` with the *lander's* handle instead of the
pipeline owner's, handing the lander full **proof + difficulty** credit for work
they only **dispatched**.

The maintainer (cgbarlow) confirmed `mac-158f` is ohdearquant's machine and asked
to re-attribute **all** such records — including the maintainer's own 72, which
this *removes* from their solver credit.

`agent≜` is the ground truth for who *proved* a goal (the machine/pipeline);
`solver≜` should equal the agent's owner. Dispatch credit for the lander is a
separate term the leaderboard already computes from PR authorship, so the lander
keeps the (smaller, correct) dispatch credit and loses only the mis-assigned
proof credit.

## WH(Y) Decision Statement

**In the context of** ADR-079/088 correcting `mac-158f`'s provenance and difficulty
while leaving `solver≜` alone, and 254 `mac-158f` records crediting two *landers*
(`cgbarlow` 134, `perttu` 120) rather than the pipeline's owner `ohdearquant` —
proof credit assigned to whoever opened the dispatched PR, not whoever's pipeline
proved the goal,

**facing** the principle that `solver≜` (proof credit) must reflect *who proved
the goal* — the `agent≜`-identified pipeline — not who landed the PR (already
captured by the leaderboard's separate dispatch term); the maintainer's confirmation
that `mac-158f` is ohdearquant's pipeline; and the maintainer's decision to
re-attribute all of it, *including their own 72 records*, accepting the change to
three contributors' standings,

**we decided for** adding a **third correction pass** to the existing idempotent
relabel sweep — an `_AGENT_OWNER = {"mac-158f": "ohdearquant"}` table and a pure
`correct_solver(text)` that rewrites `solver≜` to the declared owner for any record
whose `agent≜` is owned, composing with the ADR-079 provider/model relabel so a
record is fixed in every dimension in one pass — reusing ADR-079/087/088's exact
delivery: provenance-driven, idempotent, self-healing on the hourly + push-triggered
`attribution-relabel` workflow, **no one-shot corpus rewrite in this PR**,

**and neglected** leaving the mis-attribution (rejected — it overstates the landers'
proof+difficulty credit and understates ohdearquant's, the inverse of the integrity
ADR-079/088 pursued); a one-shot migration PR (rejected — same live-corpus reasoning
as ADR-079/087/088: only an idempotent sweep survives a churning corpus); scoping
the rewrite to *template* records only (rejected — ownership is by pipeline/machine,
so the lone genuine `claude/sonnet` `mac-158f` proof is ohdearquant's too, and it
already credits ohdearquant, so the agent-level rule no-ops on it); and a
general "dispatch ⇒ re-attribute" rule (rejected — too broad; this corrects exactly
one declared agent-owned pipeline, every other agent's `solver` stays untouched).

## Decision

- `relabel_attribution.py` gains `_AGENT_OWNER` (`mac-158f → ohdearquant`) and a
  pure `correct_solver(text) -> (text, changed)`: rewrites `solver≜` to the owner
  iff the record's `agent≜` is owned and the current solver differs. Idempotent;
  unowned agents and already-correct records are no-ops.
- The sweep's Pass A applies `correct_solver` on top of `relabel_record`, writing
  once when either changed, and reports a third summary line
  (`solver re-attribution: … N record(s)`).
- This is the **one** place the sweep moves `solver≜`, and only for a declared
  agent-owned pipeline. ADR-079/088's "solver never changes" holds for every other
  agent.

## Consequences

- 254 records (cgbarlow 134, perttu 120) re-attribute to `solver≜ohdearquant` on
  the next sweep. Downstream, the leaderboard regen lowers cgbarlow's and perttu's
  `credited_proofs`/`difficulty_points` and raises ohdearquant's; the landers gain
  the corresponding **dispatch** credit (their PRs now land for *another*
  contributor), so their net score barely moves while the proof counts become
  honest. cgbarlow's `credited_proofs` 191 → 119.
- **Recurrence is self-healing**: because the rule lives in the hourly + push-triggered
  idempotent sweep, any *future* `mac-158f` proof landed under the wrong solver is
  corrected within a sweep cycle — the same guarantee ADR-079 gives for provenance.
  Source-level prevention (stamping `solver≜` from the pipeline operator, not the PR
  lander, at submission time) is a separate follow-up.
- `attribution-relabel.yml`'s header is updated: the sweep now *does* move `solver≜`
  for agent-owned pipelines (it previously asserted solver/credit never changes).
- A new owned pipeline is a one-line `_AGENT_OWNER` addition; tests cover the
  re-attribution, idempotence, unowned-agent safety, and one-pass composition with
  the provider/model relabel.
