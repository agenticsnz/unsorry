# SPEC-086-A: Validator Role — Attestations, Credit, and Anti-Foul-Play

Implements: [ADR-086](../ADR-086-Validator-Role-Creditable-Distributed-Verification.md) · Status: Draft (pre-acceptance) · Updated: 2026-06-22

This spec defines the **contract** for the validator role: a first-class, creditable, distributed verifier that publishes signed reproducible attestations, governed so that those attestations earn credit and penalise foul play **without ever becoming load-bearing for soundness**. It builds on [SPEC-049-A](SPEC-049-A-Decentralised-CI-Runner-Architecture.md) (tiered split + mandatory trusted central re-check) and is intentionally implementation-light: the decision and rationale are in [ADR-086](../ADR-086-Validator-Role-Creditable-Distributed-Verification.md). It is a **draft** because ADR-086 is Proposed; constants marked *tunable* are placeholders pending pilot data.

## 1. Roles

Three logical roles, separate in protocol / DB / rewards / audit log; one binary may run several (`unsorry-node --roles calculator,validator`).

- **Calculator** — today's prover (`swarm/agent.sh --prove`). Produces candidate proofs. Output is *advisory* (SPEC-049-A §1, the untrusted contributor runner).
- **Dispatcher** — today's `swarm/run.sh`. Produces assignment + queue/ordering metadata. If it also validates, that validation is **one ordinary validator vote with no positional weight**.
- **Validator** — runs `leanchecker` (or the portable `lean4export` cross-checker) over an assigned candidate and publishes a signed attestation. New in this spec.

## 2. The load-bearing invariant (normative — inherited)

A validator attestation is a **claim about execution, never a trusted input to soundness**. SPEC-049-A §2 stands unchanged: a proof is admitted to `UnsorryLibrary` **only** by the mandatory trusted central re-check at **p = 1**, which re-derives the statement from canonical goal source, re-elaborates the changed-module reverse-import closure from source, and runs `leanchecker` + `axiom_audit` + ADR-011 binding on the **trusted** surface. **No quorum of attestations, however large, gates promotion** in this spec — peers gate only a *pre-promotion* lane (§7). An attestation that gated a promotion is a **soundness defect**, not an optimisation. Lowering the central re-check below p = 1 for promotion is **not specified here**: it would amend ADR-049's p = 1 invariant and requires its own ADR + SPEC.

Rationale specific to unsorry: accepted proofs become **imported dependencies** (ADR-009/010), so a falsely-promoted proof cannot be cleanly rolled back — promotion must be *prevention*, and prevention is the deterministic gate. Attestations provide **detection, offload, scaling, and credit**, not finality.

## 3. Attestation record (schema)

A validator publishes one record per (proof, validator) into the audit log (Git/AISP, ADR-003), e.g. `attestations/<proof_sha>.<validator_id>.aisp`:

```
attest≜{
  proof_sha≜<sha256 of the candidate's library module(s)>;   # what was checked, byte-exact (ADR-048)
  goal_id≜<id>; commit≜<git sha>;
  verdict≜valid | invalid;
  checker≜leanchecker | lean4export; checker_ver≜<hash>;
  toolchain≜<lean-toolchain hash>; mathlib≜<release tag>;     # reproducibility context (ADR-002)
  validator≜<registered id>;                                  # ADR-054 identity
  assigned_by≜<dispatcher id | self>; independent≜true|false; # false if validator == calculator
  ts≜<iso8601>; deadline_met≜true|false;
  sig≜<ed25519 over the canonical-serialised fields above>    # ADR-054 key
}
```

An attestation is **recorded** iff: the signature verifies against a registered validator key; `proof_sha`/`commit`/`goal_id` reference a real pending candidate; `toolchain`/`mathlib` are present; and `ts` is within the assignment deadline. Recording is **not** acceptance of the verdict — it is an auditable claim. `validator≜` becomes a first-class provenance field alongside `solver≜`/`agent≜`/`provider≜`, surfaced as a validator dimension on the leaderboard.

> **Note (normative):** none of these fields *prove execution* — they are predictable for a deterministic public computation (§5). They bind the claim to an identity and a context so it is auditable and slashable; honest execution is enforced by §5, not by the schema.

## 4. Credit and penalty

Distinct from calculator credit. On the **trusted outcome** (central re-check or resolved challenge) for a proof a validator attested:

| Event | Effect |
|---|---|
| correct attestation, in deadline, independent | **base credit** |
| correctly flagged an **invalid** that others passed | **bonus credit** (the behaviour we most want) |
| attestation matches majority but contradicts trusted outcome | **false attestation → penalty** (§6) |
| missed deadline / no-show on assignment | `timeout_count++` (reputation drag, no credit) |
| verdict ≜ valid on a **honeypot** (known-invalid) | **false attestation → penalty** (§5) |

Credit is **never** granted for agreeing with the majority per se — only for matching the *trusted* outcome. This removes the rubber-stamp incentive.

## 5. Honeypot discipline (anti-rubber-stamping — normative)

Proof-of-execution is unattainable for deterministic public computation (ADR-086): a node can emit a correct §3 record without running anything. The defence is statistical.

- The dispatcher injects **honeypots** — candidates known (by the trusted gate) to be **invalid** — into validator assignment streams, indistinguishable from real work to the validator.
- A validator that attests `verdict≜valid` on a honeypot has produced a **provable false attestation** → §6 penalty.
- **Rate `h`** (fraction of a validator's assigned checks that are honeypots) is a **tunable security parameter**, set so blind-attesting is −EV. With base reward `r` per attestation, penalty `p` per false attestation, and `c` the cost a validator saves by skipping the real check:
  - blind "valid" EV per task ≈ `r − h·p`; honest EV per task ≈ `r − c`.
  - require **`h·p > c`** ⇒ **`h > c/p`** so honest dominates.
  - Bootstrap default: `h ≈ 0.1–0.2` (tunable), decaying as `validator_reliability_score` matures; never below a floor `h_min` (tunable) so policing never fully stops.
- Honeypots are **not** soundness — they police *credit integrity*. A honeypot that escapes detection costs nothing to correctness (it never reaches the library; the trusted gate rejects it anyway).
- Under the retained **p = 1** central re-check, the trusted verdict confirms or contradicts **every** attestation, so any real proof a validator mis-attests is caught and scored (§6) — honeypots additionally police validators who would blind-stamp proofs they *expect* to be valid. (If a future ADR lowers central p < 1, random re-sampling would replace this automatic comparison — out of scope here.)

## 6. Reputation and penalty (ADR-054 substrate)

Per-validator signals: `correct_attestations`, `false_attestation_count`, `timeout_count`, `dispute_success_rate`.

- `validator_reliability_score` = an EWMA over (trusted-confirmed) outcomes, e.g. reward `+1` for a correct attestation, `−κ` for a false one (`κ ≫ 1`, tunable) — false attestations dominate the score so a single confirmed lie is expensive.
- **Standing thresholds (tunable):** a validator must hold `score ≥ θ_quorum` for its attestations to *gate* (Phase 2+); below `θ_demote` it is dropped to the bootstrap tier (central-rechecked, attestations measured-only); a confirmed false attestation triggers an immediate score hit **and** a temporary suspension (`susp_window`, tunable) — the "slash" (reputation, not funds; ADR-007: identity/reputation are never load-bearing for *correctness*, only for *credit and assignment*).
- All inputs to the score are **trusted outcomes** (central re-check / resolved challenge / honeypot), never peer-majority — consistent with §4.

## 7. Promotion rule (phased — mirrors ADR-086)

- **Phase 1 — bootstrap.** Calculators produce; ≥3 validators attest (≥1 `independent`); **central CI re-checks 100% (p = 1)**; reputation built from attestation-vs-trusted agreement; honeypots live; quorum is **measured, not gating**.
- **Phase 2 — pre-promotion offload (not a promotion gate).** A **quorum** (e.g. 2-of-3, ≥1 `independent`, dispatcher unweighted) of `score ≥ θ_quorum` validators gates a **pre-promotion lane only** — prioritisation, credit, and pre-filtering (a quorum-rejected candidate never reaches the central gate, saving its compute). The central re-check stays **p = 1 at promotion** (SPEC-049-A unchanged). An open **challenge window** of duration `W` (tunable) lets any node overturn a *peer* verdict with a reproducible counter-result (a failing `leanchecker` transcript on the same `proof_sha`+`toolchain`); the **kernel adjudicates** by re-running on the trusted gate; a successful challenge drops the candidate from the lane, penalises false attesters (§6), and credits the challenger.
- **Phase 3 — cheaper promotion gate (future; amends ADR-049).** The promotion gate stays guaranteed-honest, deterministic, and **p = 1**, but becomes **cheaper / portable** (e.g. `lean4export`) so its cost falls. *Sampling* the promotion gate (central p < 1, leaning on proven reputation) is **out of scope** — a separate ADR + SPEC amending ADR-049's p = 1 invariant, gated on pilot reputation data.

## 8. Conformance (defined for the eventual implementation)

- **Schema/signature:** `attest` records that fail signature, reference a non-pending candidate, or miss the deadline are rejected (recorded as malformed, never as a verdict). Pure validator unit-tested.
- **Invariant guard:** a regression test (cf. SPEC-049-A §5) asserts that **no code path admits a proof to `UnsorryLibrary` on attestations alone** while the active phase requires the trusted gate.
- **Honeypot:** a validator that attests a seeded known-invalid as `valid` is detected and penalised deterministically.
- **Reputation:** the score update is a pure, deterministic function of trusted outcomes (unit-tested); peer-majority is never an input.
- **Independence:** an attestation with `validator == calculator` is recorded but does **not** count toward the `independent` quorum requirement.

## 9. Phasing (contract milestones)

1. **M1 — schema + identity + audit log:** signed attestations recorded in Git/AISP, `validator≜` provenance, leaderboard dimension. Measured-only; central gate unchanged. (Phase 1.)
2. **M2 — honeypots + reputation:** injection, detection, scoring, penalties; standing thresholds. (Phase 1→2.)
3. **M3 — pre-promotion quorum lane + challenge window:** central re-check stays p = 1 at promotion. (Phase 2.)
4. **M4 — cheaper/portable p = 1 promotion gate** (e.g. `lean4export`); *sampling* the promotion gate (p < 1) is deferred to a separate ADR amending ADR-049. (Phase 3.)

## 10. Out of scope (each its own decision)

- Monetary/token economics (credit here is reputation + leaderboard standing only).
- The P2P assignment/transport mechanism (carried by the ADR-053 substrate).
- Cross-domain generalisation (ADR-030) — Lean is VERIFIED; this spec assumes a cheap deterministic verifier exists.
- TEE/hardware attestation (rejected by ADR-049).
- Exact numeric constants (`h`, `p`, `κ`, `θ_quorum`, `θ_demote`, `W`, `susp_window`) — pilot-calibrated at acceptance.
