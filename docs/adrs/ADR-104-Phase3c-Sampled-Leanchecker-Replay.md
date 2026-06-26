# ADR-104: Phase 3c — Sample the Leanchecker Kernel Replay at p < 1 with nanoda as the Every-Proof Kernel (amends ADR-049)

| Field | Value |
|-------|-------|
| **Decision ID** | ADR-104 |
| **Initiative** | verification throughput (Phase 3c, Track B) |
| **Proposed By** | unsorry maintainers |
| **Date** | 2026-06-26 |
| **Status** | Proposed — **design banked, NOT for enablement yet** (see §Enablement gates) |

## Context

ADR-097 (Phase 3b) replaced the Gate A **axiom audit** with a nanoda scoped-export check and
kept the `leanchecker` kernel replay at **`p = 1`**. It named the one remaining lever to reach
~3–4× throughput — *sampling or replacing the leanchecker replay at `p < 1`* — and explicitly
deferred it here as "a separate ADR amending ADR-049." This is that ADR.

**Two facts frame the decision, and they pull in opposite directions:**

1. **The lever is real.** With the audit gone (ADR-097), the `leanchecker` replay is now the
   Gate A wall-clock long pole *and* the largest fixed consumer of the Namespace concurrency
   budget. Sampling it at `p < 1` is the only remaining structural cut to per-PR verification
   cost — the path ADR-097 said gets to ~3–4×.

2. **Verification is not currently the binding constraint.** Measured 2026-06-26 over the first
   day of ADR-097 in production: realized merge throughput is **flat at ~17/h**, *below* the
   historical ~24/h ceiling, with Gate A running with slack (≈8 runs in flight against a ≈20
   cap). The recent decline in raw proofs/h is a **composition shift** — the swarm draining
   large homogeneous template batches and moving onto smaller, more diverse, and (per the four
   v2.0.0 benchmark suites) genuinely harder targets — not a verification stall. The binding
   constraint right now is **proof supply**, not CI.

The honest consequence of (2): **lowering `p` would spend hard-won soundness margin to optimize
a stage that is not currently the bottleneck.** So this ADR defines the mechanism and its
acceptance gates, but ships **disabled** (`p = 1`), and conditions enablement on verification
*becoming* the constraint again — not merely on the mechanism being ready.

What makes `p < 1` *thinkable* at all is ADR-097: nanoda is now a genuine independent Lean
kernel that **kernel-type-checks every covered proof** (the full def-eq check, gate-2 review
`tc.rs:92-93`), not just an axiom-footprint checker. So even at `p < 1`, **every promoted proof
is still kernel-checked** — by nanoda — and `leanchecker` becomes a *cross-kernel agreement
sample* on top, rather than the sole per-proof kernel.

## Decision

**Introduce an operator knob `p_replay = vars.UNSORRY_REPLAY_SAMPLE` (default `1.0`) that
samples the central `leanchecker` replay. Every proof remains kernel-checked by nanoda; a
fraction `p_replay` is additionally replayed by Lean's own kernel; the daily full-replay
backstop (ADR-048) re-checks 100% within 24 h.** This **amends ADR-049's `p = 1` invariant** —
from "Lean's own kernel synchronously re-checks every promoted proof" to:

> Every promoted proof is synchronously re-checked by an **independent** Lean kernel (nanoda);
> Lean's own kernel re-checks a sampled fraction synchronously and **all** of it within 24 h.

Mechanism (full normative form in SPEC-104-A):

1. **Every covered proof: nanoda kernel + axiom check** (ADR-097, unchanged) — load-bearing.
2. **Sampled `leanchecker` replay.** Selection is **deterministic from the proof's content hash**
   (not contributor-controllable and not time-based), so an author cannot influence whether
   their proof is replayed, and the same proof always lands the same way. `p_replay = 1.0` ⇒
   every proof replayed (today's behavior, the default).
3. **Disagreement ⇒ HALT, not merge.** Any nanoda-accepts / leanchecker-rejects (or vice versa)
   on a sampled proof is a **kernel-soundness emergency**: freeze autonomous merges and page a
   code owner. A disagreement is never resolved by "trust one of them."
4. **Fail-closed.** If sampling infrastructure is unavailable, or the base/diff is untrusted, or
   nanoda did not cover the PR, **replay everything** (`p_replay` treated as `1.0`).
5. **Backstop unchanged.** ADR-048's daily full `leanchecker` replay over `main` still runs, so
   every proof is Lean-kernel-replayed within 24 h regardless of `p_replay`.

## Consequences

**Throughput (the prize, when it's the constraint).** At `p_replay = p`, the replay lane's
per-PR runner cost scales ~`p`. Combined with ADR-097's audit removal this is the path to the
~3–4× ceiling ADR-097 named — *if and when* CI is the binding constraint. Per the Context, it is
not today, so the realized gain on enablement-now would be ~zero. This is why the knob ships at
`1.0`.

**Soundness (the cost, stated plainly).** `p < 1` weakens the *synchronous* guarantee that
**Lean's own kernel** has re-checked a given proof at merge time, to a *probabilistic* one
(`p`) plus an *eventual* one (≤24 h via backstop). The residual exposure is a proof that nanoda
kernel-accepts but Lean's kernel would reject — a nanoda kernel-soundness bug — that misses the
`p`-sample and merges, living up to 24 h until the backstop halts the swarm. At `p = 1` this
exposure is nil (status quo). This is a genuine reduction in margin, not a free lunch, and the
enablement gates below exist to bound it with evidence before any `p < 1` is set.

**Trust surface.** Setting `p_replay < 1` makes **nanoda's kernel check** (not just its
axiom-footprint check) load-bearing for the un-sampled fraction. The sampling driver and the
`p_replay` var join the ADR-019 CODEOWNERS trust surface; lowering `p_replay` is a code-owner
decision, never autonomous.

## Enablement gates (ALL required before any `p_replay < 1`)

- **G1 — production agreement at scale.** A sustained record of **100% nanoda ↔ leanchecker
  agreement** over a large, diverse proof corpus in production. Cheaply accumulated *now*: ADR-097
  already runs both on the fallback path; run `leanchecker` at `p = 1` *alongside* nanoda during
  bed-in and log every agree/disagree. Target: ≥N weeks and ≥M proofs with zero disagreements
  (N, M set at enablement-proposal time).
- **G2 — deepened nanoda kernel review.** ADR-097's gate-2 was a "qualified yes" for
  *axiom-footprint* co-gating. Relying on nanoda's *kernel* verdict for an un-replayed proof
  needs more: a **differential corpus replay** (the entire library exported and checked by nanoda,
  matched 1:1 against leanchecker) and **differential fuzzing** (mutated/ill-typed terms, nanoda
  and leanchecker must agree on every reject). Pin re-reviewed.
- **G3 — sampling mechanism verified.** Deterministic-from-content-hash selection (unbiased,
  not author-influenceable), fail-closed on infra/untrusted-diff, and 24 h backstop coverage —
  all under conformance test (SPEC-104-A §6).
- **G4 — verification is the binding constraint.** Evidence that Gate A is at/near its
  concurrency ceiling (in-flight pinned at the cap, queue backlog) so the freed margin buys
  realized throughput — not merely a lower bill on a non-bottleneck. **Do not spend soundness
  margin on a stage that isn't the constraint.**

Enablement is a **separate, code-owner-approved PR** that sets `vars.UNSORRY_REPLAY_SAMPLE`
below `1.0`, citing G1–G4 evidence. This ADR landing does **not** change runtime behavior.

## Alternatives considered

- **Replace leanchecker entirely with nanoda (`p_replay = 0`).** Rejected: bets the kernel oracle
  wholly on an unaudited `0.4.10-beta` checker with no Lean-kernel cross-check except the daily
  backstop. Sampling keeps a live cross-kernel agreement signal; `p = 0` discards it.
- **Enable `p < 1` now that the mechanism is ready.** Rejected per G4 — verification is not the
  current bottleneck (supply is), so it would spend margin for ~zero realized gain. Bank the
  design; enable when the constraint returns to CI.
- **Sample by wall-clock / round-robin / contributor.** Rejected: time- or author-correlated
  selection is biasable (an adversary can aim a bad proof at an un-sampled slot). Content-hash
  selection is uniform and uncontrollable.
- **Lower the daily backstop cadence to save more.** Rejected: the ≤24 h eventual-replay bound is
  the floor that makes `p < 1` tolerable at all; weakening it widens the exposure window.

## References

ADR-049/SPEC-049-A (`p = 1` invariant — **this ADR amends it**), ADR-097/SPEC-097-A (Phase 3b,
nanoda kernel-checks every proof — the precondition), ADR-096 (Phase 3a anchor + gates),
ADR-063 (sharded leanchecker replay — the lane being sampled), ADR-048 (daily full-replay
backstop — the eventual-replay floor), ADR-011 (binding gate, retained), ADR-019 (CODEOWNERS
trust surface), ADR-058 (runner roles / required-context discipline). Roadmap #5678; tracking
#5684. Companion CI cost cut: cache the pinned checker binaries (#6660).
