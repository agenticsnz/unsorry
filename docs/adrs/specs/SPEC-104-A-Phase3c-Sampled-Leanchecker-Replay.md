# SPEC-104-A: Phase 3c — sampled leanchecker replay (`p_replay < 1`)

Implements: [ADR-104](../ADR-104-Phase3c-Sampled-Leanchecker-Replay.md) · builds on
[SPEC-097-A](SPEC-097-A-Phase3b-Nanoda-Replaces-Gate-A-Axiom-Audit.md) /
[SPEC-063-A](SPEC-063-A-Sharded-Gate-A-Kernel-Replay.md) /
[SPEC-049-A](SPEC-049-A-Decentralised-CI-Runner-Architecture.md) · Status: Draft —
**design only, ships disabled (`p_replay = 1.0`)** · Updated: 2026-06-26

Contract for sampling the central `leanchecker` replay while nanoda remains the every-proof
kernel. This SPEC defines the mechanism, its invariants, and the conformance suite that must be
green **before** any `p_replay < 1` is ever set; it does **not** authorize enablement (ADR-104
§Enablement gates G1–G4 + a separate code-owner PR do).

## 1. The knob

- `p_replay = vars.UNSORRY_REPLAY_SAMPLE`, a float in `[0, 1]`, **default `1.0`**.
- `1.0` ⇒ today's behavior exactly: every changed library module is leanchecker-replayed
  (ADR-063), so landing this SPEC is a **no-op** until an operator lowers it.
- `0` is **forbidden** by the planner (rejected at parse): `p_replay = 0` would discard the
  live cross-kernel agreement signal (ADR-104 alternatives). Clamp the usable range to
  `[p_min, 1.0]` with `p_min > 0` (e.g. `0.05`).

## 2. Selection (deterministic, unbiased, fail-closed)

For each candidate replay target (a locally-derived module name `Unsorry.Foo`, per SPEC-049-A §2
— never a contributor artifact):

1. `h = sha256(canonical_target_id)` where `canonical_target_id` is the **module name + its
   source content hash** as already rebuilt locally — **not** the PR number, branch, author,
   wall-clock, or any contributor-supplied field.
2. Replay iff `(int(h[:16], 16) / 2**64) < p_replay`. So selection is:
   - **uniform** — expected sampled fraction is `p_replay`;
   - **deterministic** — the same proof is always sampled the same way (no flaky gate);
   - **uncontrollable** — an author cannot aim a proof at an un-sampled slot (the hash is over
     the rebuilt content, fixed by the math, not by anything they choose).
3. **Fail-closed to `p_replay = 1.0`** (replay everything) when any of:
   - the diff/base is untrusted (`forces_full_replay`, SPEC-049-A) — already the full-scope path;
   - `nanoda` did **not** cover the PR (`gate_a_nanoda.covered != 'true'`) — no every-proof kernel
     stands in for the un-sampled fraction, so the sample cannot be reduced;
   - `vars.UNSORRY_REPLAY_SAMPLE` is unset, unparseable, or out of `[p_min, 1.0]`.

The un-sampled targets are **not** skipped silently: the replay-plan emits them to the cover
job's report as `deferred-to-backstop`, so the sticky comment states exactly which modules were
not synchronously Lean-replayed and that the daily backstop (ADR-048) will.

## 3. Every proof stays kernel-checked

`p_replay < 1` is permitted **only because** `gate_a_nanoda` (ADR-097) kernel-type-checks every
covered proof. The contract:

- **Invariant K1** — for every promoted proof, *some* Lean kernel synchronously accepted it at
  merge time: nanoda always, leanchecker with probability `p_replay`.
- **Invariant K2** — Lean's *own* kernel re-checks **100%** within 24 h (ADR-048 daily full
  leanchecker replay over `main`, unchanged and uncapped by `p_replay`).
- **Invariant K3** — the ADR-011 binding gate is unaffected; statement-binding still gates 100%.

## 4. Disagreement is a halt, never a merge

On any sampled target where nanoda and leanchecker **disagree** (one accepts, one rejects):

1. The replay job **fails** (so `gate-a` fails — the PR does not merge).
2. A **swarm-halt** signal is raised (the autonomous-merge backstop pauses) and a code owner is
   paged: a cross-kernel disagreement is a soundness emergency, not a flake.
3. Resolution is **manual** — never "trust nanoda" or "trust leanchecker". The pinned nanoda
   commit and/or the proof are quarantined until root-caused.

The daily backstop applies the same rule over `main`: a backstop disagreement halts the swarm.

## 5. Workflow shape

- `gate_a_replay_plan` reads `vars.UNSORRY_REPLAY_SAMPLE` + `gate_a_nanoda.covered`, applies §2,
  and emits the (possibly reduced) shard matrix plus the `deferred-to-backstop` list. Cheap
  ubuntu job, no build (as today).
- `gate_a_replay` (matrix) and `gate_a_replay_cover` are unchanged except the cover job records
  the deferred list and asserts §4 (no disagreement) for the sampled set.
- The required **`gate-a` context name is unchanged** (ADR-058); the aggregator still requires
  `gate-a-nanoda` AND `gate-a-replay` (replay now meaning "the sampled set passed", with the
  backstop owning the remainder).

## 6. Conformance suite (must be green before any `p_replay < 1`)

In `tools/gate_a/tests/` (mirrors the ADR-063/091 shard tests + SPEC-049-A conformance):

- **selection-is-uniform** — over a synthetic corpus, sampled fraction ≈ `p_replay` within
  tolerance; **selection-is-deterministic** — same target ⇒ same decision across runs;
  **selection-ignores-contributor-fields** — decision is invariant to PR number / author /
  branch / time (only module-name + content hash feed it).
- **fails-closed-when-nanoda-not-covered** — `covered != 'true'` ⇒ full replay regardless of
  `p_replay`; **fails-closed-on-untrusted-diff** — `forces_full_replay` ⇒ full replay;
  **rejects-p-zero / clamps-out-of-range** — `p_replay ∉ [p_min, 1]` ⇒ full replay.
- **default-is-p1-noop** — with the var unset, the emitted matrix equals today's ADR-063 matrix
  exactly (landing this SPEC changes nothing).
- **deferred-targets-are-reported** — un-sampled modules appear in the cover report as
  `deferred-to-backstop`, never dropped silently (SPEC-049-A "no silent caps").
- **disagreement-fails-and-halts** — a mocked nanoda/leanchecker disagreement fails the cover
  job and raises the halt signal.

## 7. References

ADR-104 (this SPEC's decision), ADR-097/SPEC-097-A (nanoda every-proof kernel — the
precondition for K1), ADR-063/SPEC-063-A (the replay lane being sampled), ADR-049/SPEC-049-A
(`p = 1` invariant amended; locally-derived-targets-only invariant retained), ADR-048 (daily
backstop — K2's floor), ADR-058 (required-context discipline), ADR-019 (CODEOWNERS).
