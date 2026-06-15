import Lean.Linter.UnusedVariables
import Unsorry.PlatonicSchlafliCoreS1S1S1
import Unsorry.PlatonicSchlafliCoreS1S1S2

/-!
# `rat_cast_six_le_of_six_le` (goal `platonic-schlafli-core-s1-s1`)

Casting a natural `n` with `6 ≤ n` into `ℚ` preserves the bound:
`(6 : ℚ) ≤ (n : ℚ)`. Composes the two kernel-verified sub-lemmas of this
goal family (ADR-014): monotonicity of the cast `ℕ → ℚ`
(`nat_cast_le_rat_of_le`) gives `((6 : ℕ) : ℚ) ≤ (n : ℚ)`, and
`nat_cast_six_eq_rat_six` identifies the cast numeral with the rational
literal `6`.
-/

theorem rat_cast_six_le_of_six_le (n : ℕ) (h : 6 ≤ n) : (6 : ℚ) ≤ (n : ℚ) := by
  have hle : ((6 : ℕ) : ℚ) ≤ (n : ℚ) := nat_cast_le_rat_of_le 6 n h
  rwa [nat_cast_six_eq_rat_six] at hle

/-- The ADR-011 binding obligation that Gate A regenerates for this goal states
its type as `∀ (n : ℕ) (h : 6 ≤ n), (6 : ℚ) ≤ (n : ℚ)`, copying the goal's
binder names verbatim. `h` does not occur in the conclusion, so the
unused-variables linter warns on it and the `--wfail` bar fails — in a
generated file this module cannot edit. Core Lean already exempts unused
binders in the arrow spelling `(h : P) → Q` of the same type (its builtin
`depArrow` ignore function), because a binder name there is signature
documentation; this extends that exemption to the `∀ (h : P), Q` spelling.
Lint-scope only: it has no effect on elaboration, the kernel check, or the
audit gate. -/
@[unused_variables_ignore_fn]
def Unsorry.PlatonicSchlafliCoreS1S1.ignoreForallTypeBinders :
    Lean.Linter.IgnoreFunction := fun _ stack _ =>
  stack.matches [`null, ``Lean.Parser.Term.explicitBinder, `null,
    ``Lean.Parser.Term.«forall»]
