# SPEC-010-A: Affinity-Weighted, Gap-Based Selection

Implements: [ADR-010](../ADR-010-Affinity-Gap-Selection.md) · Status: Living · Updated: 2026-06-10

Replaces the lexicographic goal selection of SPEC-007-A with the affinity + gap ranking the protocol (`⟦Γ:Affinity⟧`) and design doc (Components §6) specify. This is **pure coordination/queue logic** — it never touches Gate A and is never load-bearing for soundness.

## Ranking

Among the goals that survive the existing candidate filters (SPEC-007-A prove step 2 / translate step 2 — phase, status, claim-cap, not-already-proved), selection:

1. **Drops the non-viable:** any goal whose affinity `< τ_v` (= −5, `config.TAU_V`) is skipped — it has failed enough that its pattern is below viability and awaits re-decomposition (Stage C, ADR-009). Until decomposition exists, below-`τ_v` simply means deprioritised-out-of-selection.
2. **Orders the rest by `(affinity desc, gap asc, id asc)`.** The lexicographic id tie-break keeps trials reproducible.

`agent.sh`'s `py_helper` `candidates` / `prove-candidates` commands emit goals in this order; the loop claims the first.

## Affinity

A goal's affinity is an **optional** `aff≜<signed-int>` field in its record's `⟦Λ:Artifact⟧` block.

- **Absent or malformed ⇒ 0.** Affinity is strictly advisory; a missing or garbled value degrades to neutral and never crashes selection (`_affinity` in `agent.sh`; test `test_affinity_degrades_on_garbage`). It is therefore **not** Gate B-enforced — the Gate B validator ignores the field (it validates only the known coordination fields), and a wrong score can only misroute effort, never admit a bad proof.
- **`+1` on a merge (`⊕`, `config.AFFINITY_MERGE`).** When a prove PR merges, the proved goal's record is bumped `+1` in the same gated PR (`check_in_proof` → `aff-bump`). This reinforces the pattern that produced a proof (provenance; the proved goal itself leaves the candidate pool).
- **`−10` on a failed attempt (`⊖`, `config.AFFINITY_FAIL`).** When a prove attempt exhausts its budget, `demote_goal` opens a small gated PR editing only `goals/<goal>.aisp`'s `aff` field (`affinity(<goal>): -10 …`). Editing a goal `.aisp` is not a Lean path, so Gate A short-circuits (~30 s) and Gate B validates; the penalty persists so the goal is deprioritised and, below `τ_v`, skipped. Best-effort — a failed demote never blocks the cycle.

The asymmetry (`+1` / `−10`) deliberately favours proven approaches. In Stage B, affinity attaches per **goal** as a stand-in for the design doc's per-**pattern** affinity, until a pattern model exists; the load-bearing selection effect is the `−10`/skip path that hands persistently-failing goals to re-decomposition.

The library index `aff`/`use` fields (set to 0 by `render-index`) remain for proved-lemma provenance and future pattern aggregation; this spec does not yet drive selection from them.

## Gap

`gap(g) ≜ |deps(g) ∖ proved|` — the count of `g`'s dependency goals (`deps≜⟨…⟩`) that are not yet proved (no `library/index/<sha>.aisp` names them). Fewer unproved dependencies ⇒ closer to the merged library ⇒ preferred. Computed in `_gap`; `proved` is the existing `_proved_goals(library)` set. Translate goals carry `deps≜⟨⟩`, so their gap is 0 and the order degenerates to lexicographic on a flat backlog (no behaviour change for Phase-0/1 translation).

## Constants (mirror `swarm/protocol.aisp`, via `tools/gate_b/config.py`)

| Constant | Value | Meaning |
|---|---|---|
| `TAU_V` | −5 | viability threshold (strictly below ⇒ skipped) |
| `AFFINITY_MERGE` | +1 | `⊕` per merge |
| `AFFINITY_FAIL` | −10 | `⊖` per failed attempt |

`py_helper aff-delta merge|fail` exposes the deltas so the shell never hardcodes them (DRY).

## Acceptance criteria (`--self-test`, hermetic)

1. `test_affinity_ranking` — higher affinity first; equal affinity → lexicographic.
2. `test_gap_ranking` — smaller gap wins over lexicographic order; proving a dependency drops the dependent's gap.
3. `test_viability_skip` — a goal below `τ_v` is excluded; exactly at `τ_v` it is viable (but ranks by its low affinity).
4. `test_affinity_bump_math` — `aff-bump` inserts when absent, accumulates when present, reflects the configured deltas; a goal carrying `aff` still validates under Gate B.
5. `test_affinity_degrades_on_garbage` — a non-integer `aff` is read as 0; selection never crashes.
