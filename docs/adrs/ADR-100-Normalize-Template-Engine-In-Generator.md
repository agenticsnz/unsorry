# ADR-100: Normalize Deterministic-Template Provenance in the Leaderboard, and Harden the Sweep

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-100 |
| **Initiative** | corpus & attribution integrity |
| **Proposed By** | Chris Barlow (maintainer) |
| **Date** | 2026-06-26 |
| **Status** | Accepted |

## Context

Deterministic-template pipelines record a placeholder `provider≜claude;
model≜template-*` until the [attribution-relabel sweep](../../tools/repo/relabel_attribution.py)
(ADR-079/086/087/088) rewrites it to the honest engine (`lean/decide`, `lean/ring`,
`python/sympy`). The sweep is idempotent and runs hourly + on push, but it is **not
instantaneous**: a proof lands, sits as `claude/template-*` for the minutes until
the next sweep, and is corrected after. The sweep is also contended — under the
corpus's push rate ~⅔ of its runs are cancelled by the concurrency group.

That **lag window** leaks: if a leaderboard regen fires after a template proof
lands but before the sweep corrects it, the model distribution snapshots a phantom
`claude / template-induction-ring` model, which can even reach the guild's model
registry. Observed live 2026-06-26: a proof landed 01:39, regen at 01:45 captured
`claude / template-induction-ring`, the sweep corrected it 01:47 — but the artifact
showed the phantom in between.

Two gaps underlie this:
1. The board reads raw provenance, so it is only as fresh as the last sweep.
2. The sweep's `claude-web`/`seedkit` rules matched **two literal** template names
   (`template-zmod-decide`, `template-induction-ring`); a *new* template shape under
   those agents would slip through permanently (the `mac-158f` rule was already a
   broad `template-*`).

## WH(Y) Decision Statement

**In the context of** the model distribution being built from raw proof/run
provenance, and deterministic-template proofs carrying a placeholder
`claude/template-*` for the minutes between landing and the next attribution sweep,

**facing** a phantom `template-*` model surfacing on the board (and into the model
registry) whenever a regen fires inside that lag window — plus a latent gap where a
new template name under `claude-web`/`seedkit` would never be relabelled because the
rules matched two literal model strings,

**we decided for** (1) extracting the template→honest mapping into one canonical pure
`honest_engine(agent, provider, model)` and having the **leaderboard generator** fold
every proof/run through it when building the model distribution — so the board is
*correct-by-construction*, never showing a `template-*` model regardless of sweep
timing — and (2) reimplementing the sweep's `relabel_record` on the same
`honest_engine`, **suffix-matching** the Lean tactic (`*decide` → `lean/decide`,
`*ring` → `lean/ring`) so any future template name ending in a known tactic is caught,

**and neglected** only speeding up / de-contending the sweep (rejected — it narrows
but cannot close the window; a regen can always race a fresh proof), excluding
`template-*` rows outright (rejected — the proof *is* a real `lean/ring` solve and
should count under its engine, not vanish), and duplicating the mapping in the
generator (rejected — `honest_engine` is the single source of truth both the sweep
and the board consume, so they cannot drift),

**to achieve** a board on which a deterministic-template model can never appear,
independent of when the sweep last ran, and a sweep that no longer pins itself to two
hard-coded template names,

**accepting that** the generator now depends on `tools.repo.relabel_attribution`
(a pure, stdlib-only import — no cycle), and that a template under an *unknown* agent,
or with an unrecognised tactic suffix, is still left as-is by design (surfaced, not
guessed) — a one-line `honest_engine` extension when such a pipeline is introduced.

## Decision

- `honest_engine(agent, provider, model) -> (provider, model)` in
  `relabel_attribution.py` is the canonical template→engine map: `mac-158f` →
  `python/sympy` (any `template-*`); `claude-web`/`seedkit` → `lean/decide|ring` by
  tactic **suffix**; everything else unchanged (idempotent on honest input).
- `relabel_record` is reimplemented on `honest_engine` (replacing the literal
  `_RULES`/`_REWRITABLE_PROVIDERS` regex table); behaviour for the existing two
  shapes is preserved, new same-tactic shapes are now caught.
- `generate.py` folds each run and proof through `honest_engine` when keying the
  model distribution (`model_runs`/`model_proofs`).

## Consequences

- The phantom `template-*` model can no longer appear on the board, whatever the
  sweep timing — the lag window is closed at the read side; the sweep still corrects
  the on-disk records at its own pace.
- One source of truth: the sweep and the board agree by construction.
- The sweep self-heals on new template *shapes* (same-tactic) without a code change;
  a genuinely new tactic/agent is a one-line `honest_engine` addition with a test.
- `index_is_seedkit`/`index_is_mac158f` (difficulty backfill) still recognise the two
  current shapes plus any post-relabel honest record; a brand-new pre-relabel shape
  is difficulty-backfilled on the cycle *after* its provenance is relabelled — an
  accepted one-cycle lag, not a leak (difficulty is not a board-facing model label).
