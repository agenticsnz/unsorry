# SPEC-086-A: seedkit Fixture-Generation Path

Implements: [ADR-086](../ADR-086-Seedkit-Fixture-Generation-Path.md) · Status: Living · Updated: 2026-06-23

ADR-086 legitimises `tools/seedkit/` as a documented **fixture / library-growth**
origination path, distinct from sourcing, and conforms its attribution and
difficulty to the sourcing paradigm. This spec is the contract for the code,
docs, Skills, and governance changes that deliver that decision. It is
deliberately scoped to **generation going forward**; a retroactive backfill of
already-merged seedkit records is out of scope (see §8).

## 1. Deliverables

| # | Deliverable | Surface |
|---|---|---|
| D1 | Honest, identity-bearing provenance at write-time | `tools/seedkit/_artifact.py` |
| D2 | Honest difficulty on every family | `tools/seedkit/mkfiles*.py` |
| D3 | Tests pinning D1 + D2 | `tools/seedkit/tests/` |
| D4 | Kit self-description matches D1/D2 | `tools/seedkit/README.md`, module docstrings |
| D5 | Fixture path documented & disambiguated from sourcing | `README.md`, `CONTRIBUTING.md` |
| D6 | Skills cross-reference + invariant fix | `Skills/unsorry-goal-sourcing/*`, `tools/seedkit/README.md` |
| D7 | Governance posture recorded | this spec §6 + `tools/seedkit/README.md` |

## 2. Provenance contract (D1)

`write_artifacts` in `tools/seedkit/_artifact.py` currently stamps
`solver≜$SEEDKIT_SOLVER` (default `anon`), `agent≜$SEEDKIT_AGENT` (default
`seedkit`), `provider≜seedkit`, and a per-family `model≜template-*`. Replace with:

- **Solver — no silent `anon`.** Resolve the solver id as
  `solver` arg → `$UNSORRY_SOLVER` → `$SEEDKIT_SOLVER`. If none is set, **raise
  `ValueError`** (`"set UNSORRY_SOLVER or SEEDKIT_SOLVER; seedkit refuses to stamp
  anonymous provenance (ADR-086)"`) rather than writing `anon`. This matches the
  rest of the system attributing to an authenticated identity (ADR-007/023/029)
  and makes anonymous corpus injection impossible.
- **Provider — honest engine.** Default `provider` becomes **`lean`** (these are
  Lean kernel proofs, not a bespoke `seedkit` engine), matching how ADR-079 /
  the relabel sweep already classify them.
- **Model — honest tactic.** Each family passes a real engine label, not
  `template-*`:
  - `decide` for the finite-`ZMod` `decide` families (`mkfiles.py`,
    `mkfiles_residue.py`, `mkfiles_factdvd.py`);
  - `ring` for the `induction; ring` closed-form families (`mkfiles_faulhaber.py`,
    `mkfiles_telescoping.py`, `mkfiles_altgeom.py`, `mkfiles_oddsq.py`,
    `mkfiles_arith.py`, `mkfiles_shiftsq.py`).
- `agent` default stays `seedkit` (it *is* the generating agent) and remains
  overridable via `$SEEDKIT_AGENT`.

The resulting provenance line is `⟦Π:Provenance⟧{solver≜<id>; agent≜seedkit;
provider≜lean; model≜decide|ring; attempts≜1}` — valid under Gate B and requiring
no post-hoc relabel.

## 3. Difficulty contract (D2)

Every family writer hard-codes a difficulty fed straight to the goal record. The
current values (`gzmod`/`factdvd`/`arith`=3, `oddsq`/`telescoping`/`shiftsq`=4,
`altgeom`/`faulhaber`=5) overstate goals closed by a single `decide` or a fixed
`induction; ring` — exactly what the sourcing skeptic rejects as *"a short
one-tactic proof"*. **Set `difficulty=1` for every family** (the honest value the
sourcing rubric assigns to a one-tactic/template-closeable goal). The
`_artifact.py` `0 ≤ difficulty ≤ 5` Gate-B guard (GB003) is unchanged; 1 is in
band.

## 4. Tests (D3)

Add `tools/seedkit/tests/test_provenance.py` (stdlib + pytest, hermetic — writes
into a `tmp_path` cwd, asserts on returned strings / written files):

- every `mkfiles_*.write_goal` (or a representative per engine) produces a goal
  record with `difficulty≜1`;
- the index record carries `provider≜lean` and `model≜decide` (decide families) /
  `model≜ring` (ring families), and `solver≜` equal to the supplied/`$UNSORRY_SOLVER`
  id — never `anon`;
- `write_artifacts` with no solver arg and no `UNSORRY_SOLVER`/`SEEDKIT_SOLVER`
  in the environment **raises** `ValueError`;
- `$UNSORRY_SOLVER` takes precedence over `$SEEDKIT_SOLVER`.

`test_import_safe.py` continues to pass unchanged.

## 5. Documentation (D4, D5)

- **`tools/seedkit/README.md`**: update the provenance table (`solver` default →
  "required: `UNSORRY_SOLVER`/`SEEDKIT_SOLVER`, no `anon`"; `provider`/`model` →
  `lean`/`decide`|`ring`), state difficulty is 1 by the sourcing rubric, and add a
  cross-reference to the `unsorry-goal-sourcing` skill explaining seedkit is the
  **fixture** path (deterministic, proved-on-arrival) and is *not* the sourcing
  pipeline.
- **`README.md`**: amend the *"the path is the same — a worker takes an open goal
  carrying a `sorry` and proves it"* invariant so it admits the proved-on-arrival
  fixture path (one honest clause, no rewrite of the section), and name the
  fixture vector where the corpus-growth / contribution mechanisms are described.
- **`CONTRIBUTING.md`**: add **fixture generation** as a contribution mode beside
  "run an agent / propose a target / source at scale", pointing at
  `tools/seedkit/README.md`, explicitly flagged *"not sourcing — deterministic,
  kernel-verified library lemmas, proved on arrival"*.
- **Vocabulary** (used consistently across D4/D5/D6): *sourcing* = open goals for
  the swarm to prove; *fixtures (seedkit)* = batch-generated, deterministically
  proved library lemmas.

## 6. Skills & invariants (D6)

- **`Skills/unsorry-goal-sourcing/SKILL.md`** and
  **`references/triple-format.md`**: the lines stating *"a fresh goal is always
  `status≜open`, `sha≜∅`"* and *"a real 64-hex sha is only for proved/archived"*
  are true for sourcing but universalised; add a one-line **fixture exception**
  noting that seedkit (ADR-086) writes proved-on-arrival records, with a pointer
  to `tools/seedkit/README.md`, and a routing note so an agent asked to
  *"batch-generate divisibility theorems"* reaches for seedkit, not the four-gate
  sourcer.
- No change to the sourcing pipeline, gates, or `swarm/` (a CODEOWNERS surface).

## 7. Governance (D7)

seedkit lives outside `.github/CODEOWNERS`, so its PRs auto-merge on green Gate
A/B (ADR-005). This spec **keeps** that posture — fixtures are sound by
construction (truth pre-checked, kernel `decide`/`ring`, full Gate A/B before
push) and adding a code-owner gate would serialise a high-throughput generator
for no soundness gain. The governance change is **visibility, not gating**:
`tools/seedkit/README.md` documents the batch posture and the run drivers'
existing per-run logging is the audit trail. A hard per-run volume cap is
considered and **rejected here** (the `--wfail` Gate A + Gate B already bound each
artifact; volume is a corpus-curation question, not a soundness one) and left to
a future ADR if curation pressure appears.

## 8. Out of scope

- **Retroactive backfill** of already-merged seedkit records' difficulty /
  provenance — a separate change (it churns the corpus and leaderboard and
  warrants its own decision); `solver≜` proof credit is **not** stripped.
- **Folding seedkit into sourcing** (emitting `status≜open`) — rejected in
  ADR-086.
- The five-family / word-table expansion (#5210) — already merged; this spec only
  retrofits its provenance/difficulty along with the rest.
