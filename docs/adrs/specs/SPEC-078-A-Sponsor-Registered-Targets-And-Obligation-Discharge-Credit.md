# SPEC-078-A: Sponsor-Registered Targets and Obligation-Discharge Credit

Implements: [ADR-078](../ADR-078-Sponsor-Registered-Targets-And-Obligation-Discharge-Credit.md) · Status: Accepted · Updated: 2026-06-24 · Refines [SPEC-035-A](SPEC-035-A-Non-Trivial-Theorem-Enforcement.md), reuses [SPEC-012-A](SPEC-012-A-Backlog-Sourcing.md)

This SPEC accompanies an **Accepted** ADR (#5643); the mechanism is fixed. The numeric weights (credit weights, the completion bonus `B`) remain **deferred placeholders** to be set with a worked example before any organic-board change ships (ADR-078 §55). The benchmark track (ADR-092) uses per-obligation credit on a segregated cohort and does not depend on them.

## 1. The target registry

A *target* is registered through the ADR-020 sponsor channel as a content-addressed record under `targets/<target-id>/`:

- `target.aisp` — the root statement, the sponsor identity, the registration `mathlib_rev`, and a status (`open` | `complete` | `withdrawn`).
- `skeleton.aisp` — the fixed list of obligations and the ADR-009 typed dependency edges among them and to the root. Each obligation carries its canonical statement and a `credit` flag (`credited` | `glue`, §3).
- `obligations/<sha256>.lean` — one paired Lean statement per obligation, `sorry` in the body, `<sha256>` = SHA-256 of the canonical statement (plan §7), the same content-addressing the library index uses, so an obligation shared across targets is one hashed node.

The registry path `targets/**` is a CODEOWNERS trust surface (ADR-019): a registration PR cannot auto-merge on gate-green alone, it requires a code-owner review. This is the R2 guardrail — registration is double-gated (sponsor + owner), so a "low-guarded sponsor" cannot register unilaterally.

The skeleton is **immutable once registered** (ADR-018 goal-statement immutability, extended to the target's obligation set): a sponsor may not add, remove, re-split, or re-edge obligations after registration, only mark the target `complete`/`withdrawn`. A new structure is a new target with a new id. This is what denies the contributor — and the sponsor after the fact — control over the graph the credit function reads.

## 2. Discharge

A contributor discharges an obligation exactly as today: claim, prove against the obligation's Lean statement, open a `prove(...)` PR, Gate A re-verifies from scratch in the kernel (ADR-006/048), and on merge the obligation's `sorry` is replaced and its index entry recorded. No new proving path; the only change is that the proof targets a registered obligation's statement hash rather than a free-standing goal.

A target is `complete` when every obligation in its skeleton is discharged. Completion is a pure function of the registry + library index (no human step), refreshed post-merge on the ADR-036 cadence.

## 3. The registration-time full-battery probe (R1)

At **registration** (not at sourcing), each obligation is probed by an extension of `tools/sourcing/check_triviality.py` whose battery is the **full** set:

```
ADR-035 battery  ∪  { nlinarith, positivity, field_simp, gcongr }
```

ADR-035 excludes those four at *sourcing* so genuinely-hard atomic inequalities survive as standalone goals. At *target registration* the question is the opposite — is this node worth crediting as a unit of a larger proof — so closing under any of them means the node is glue, not a credited obligation.

- probe verdict `trivial` (full battery closed it) → the obligation is marked `glue`: it stays in the skeleton (a real proof has easy steps) but **earns zero board credit** when discharged.
- probe verdict `non-trivial` → the obligation is `credited`.
- probe verdict `probe-error` → surfaced, blocks registration of that obligation until fixed (it already type-checks under `UnsorryGoals`, so this is an import/open gap, per SPEC-035-A's trichotomy).

The probe is **blocking at registration** (affordable: targets are rare and sponsor-paced), which is the posture ADR-035 could not take per-merge. `mathlib_rev` is recorded on each verdict so the credited/glue split is rev-dated.

## 4. The credit function

The leaderboard tool (`tools/leaderboard/generate.py`, a CODEOWNERS surface) gains a registered-target pass:

```
credited_obligation_points(contributor) =
    Σ over registered targets T, over credited obligations o ∈ T discharged by `contributor`,
      of  1                         # one point per discharged credited obligation
    where the discharging author ≠ T.sponsor        # self-target earns 0 (the v1.28 self-dispatch rule)
      and o is counted once across all targets       # statement-hash dedup (§7)

target_completion_bonus(contributor) =
    Σ over targets T completed AND having ≥1 credited obligation, of  B   # B = placeholder
    credited to the contributors of T's credited obligations, pro-rata
    # an all-glue target's recipient set is empty → bonus 0; no completion credit
    # can be farmed from a target with no credited obligation
```

- **Score** = `credited_obligation_points + target_completion_bonus`, run dual-track alongside the existing atom credit during transition (ADR-078 Cost), with a deliberate sunset.
- **Rank key** is unchanged in shape from the current `(-credited_proofs, -difficulty_points, name)` (the leaderboard already ranks by credited count, not raw score); registered-target obligations feed the credited count.
- **Depth and fan-in** of a discharged obligation in T's skeleton are emitted into the board JSON as advisory columns (ordering/visualisation only) and are **never** summed into score or rank — the explicit ADR-078 (d) rejection.

## 5. Acceptance criteria

1. `test_skeleton_is_immutable` — a registration PR that edits an existing target's obligation set or edges fails the registry validator (extends the ADR-018 immutability check to `targets/**`).
2. `test_full_battery_marks_glue` — an obligation closable by `nlinarith` alone probes `trivial` under the registration battery and is recorded `glue`; an obligation that survives the full battery is `credited`. Fixture pair, byte-exact verdicts.
3. `test_glue_earns_zero` — discharging a `glue` obligation adds 0 to the contributor's score; discharging a `credited` one adds 1.
4. `test_self_target_zero` — a target's sponsor discharging one of its own credited obligations earns 0 (parallels the existing self-dispatch test).
5. `test_obligation_dedup` — the same canonical statement registered in two targets is one credited node; discharging it credits once.
6. `test_depth_fanin_advisory` — depth/fan-in appear in the board JSON but changing them does not change any score or rank value.
7. `test_targets_codeowner_gated` — a `targets/**` change is reported by the CODEOWNERS check as requiring code-owner review (it cannot auto-merge on gate-green alone).
8. `test_all_glue_target_no_bonus` — a completed target whose obligations are all `glue` yields a completion bonus of 0 (empty credited-recipient set); a completed target with ≥1 credited obligation distributes `B` pro-rata over its credited contributors.

## 6. Out of scope (for this SPEC)

The numeric weights (`B`, any normalisation), the migration/sunset schedule of the dual-track board, and Sybil/confederate detection beyond the existing provenance guards (ADR-023/037) are deferred. The residual sponsor-plus-owner collusion floor (ADR-078 Residue) is accepted, not engineered against here.
