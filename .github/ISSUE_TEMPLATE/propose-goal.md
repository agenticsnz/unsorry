---
name: Propose a goal
about: Register a structured proof target with a skeleton for contributors to work toward
title: "goal: <short name>"
labels: ["goal"]
---

<!--
A goal is a structured proof target: a Lean file with definitions, lemma
statements, and `sorry` obligations that contributors discharge for credit
on the goals leaderboard. Goals differ from targets in that the sponsor
provides the mathematical structure (the skeleton), not just a statement.

Requirements:
  - The skeleton must type-check with its sorries (`lake env lean <file>` succeeds).
  - Every obligation must survive the ADR-035 triviality battery (no single-tactic closes).
  - The sponsor does not earn credit for the skeleton, only for the mathematical
    design work of decomposing the problem.

A maintainer reviews and adds the `goal` label to approve.
See ADR-078 (docs/adrs/ADR-078-Sponsor-Registered-Targets-And-Obligation-Discharge-Credit.md).
-->

## Goal summary

**What this proves (plain English):**

<!-- 1-3 sentences describing the mathematical result and why it matters. -->

**Domain:** <!-- e.g. number theory, analysis, algebra, combinatorics -->

## Skeleton

**Lean file** (attach or paste):

<!--
The skeleton is a `.lean` file that type-checks under `import Mathlib` with
its `sorry` obligations in place. It defines the structures, states the
lemmas, and marks the proof obligations as `sorry`.

Paste inline for small skeletons; attach a `.lean` file for larger ones.
-->

```lean
import Mathlib

-- definitions and helper lemmas here

theorem main_result : ... := by
  sorry -- obligation 1: ...
```

**Obligation count:** <!-- How many `sorry` obligations in the skeleton? -->

**Obligation summary:** <!-- Brief description of each obligation and what proving it requires. -->

## The mathematics is already established

**Reference:** <!-- A real citation: book + section/page, paper, or textbook. The skeleton must decompose a known result, not an open conjecture. -->

## Non-triviality

<!--
Every obligation in the skeleton must survive the ADR-035 triviality battery.
If a single tactic (`rfl`, `decide`, `norm_num`, `ring`, `omega`, `simp`,
`aesop`) closes an obligation, that obligation will not be admitted.
-->

**Triviality check you ran (if any):**

```
# Run on the skeleton file:
python3 -m tools.sourcing.check_triviality <skeleton.lean>
```

## Absence from mathlib

**Why you think the result is absent:** <!-- e.g. Loogle search, Freek's 100 list, manual inspection. -->

**Absence check you ran (if any):**

```
python3 -m tools.sourcing.check_absence --pattern '<regex>'
```

## Difficulty and scope

**Estimated difficulty:** <!-- 1 (straightforward) to 5 (research-grade). -->

**Estimated LOC:** <!-- Rough line count for the completed proofs. -->

**Dependencies between obligations:** <!-- Can obligations be solved independently, or do later ones depend on earlier lemmas? -->

---

A maintainer will verify that the skeleton type-checks, run triviality and
absence checks, and approve by adding the `goal` label. Approved goals
appear on the goals board for contributors to pick up.
