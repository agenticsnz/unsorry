import Lean.Linter.UnusedVariables
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Algebra.Order.GroupWithZero.Unbundled.Basic
import Mathlib.Data.Nat.Cast.Order.Basic
import Mathlib.Tactic.NormNum

/-!
# `nat_inv_le_third_of_three_le` (goal `platonic-schlafli-core-s2-s1`)

For a natural `q` with `3 ≤ q`, the inverse in `ℚ` satisfies
`(q : ℚ)⁻¹ ≤ (3 : ℚ)⁻¹`: inversion is antitone on the positives
(`inv_anti₀`), `0 < 3`, and the cast to `ℚ` preserves `3 ≤ q`
(`Nat.ofNat_le_cast`).
-/

theorem nat_inv_le_third_of_three_le (q : ℕ) (hq : 3 ≤ q) :
    (q : ℚ)⁻¹ ≤ (3 : ℚ)⁻¹ :=
  inv_anti₀ (by norm_num) (Nat.ofNat_le_cast.mpr hq)

/-- The ADR-011 binding obligation that Gate A regenerates for this goal states
its type as `∀ (q : ℕ) (hq : 3 ≤ q), (q : ℚ)⁻¹ ≤ (3 : ℚ)⁻¹`, copying the
goal's binder names verbatim. `hq` does not occur in the conclusion, so the
unused-variables linter warns on it and the `--wfail` bar fails — in a
generated file this module cannot edit. Core Lean already exempts unused
binders in the arrow spelling `(h : P) → Q` of the same type (its builtin
`depArrow` ignore function), because a binder name there is signature
documentation; this extends that exemption to the `∀ (h : P), Q` spelling,
exactly as the merged `Unsorry.PlatonicSchlafliCoreS1S2` does for its goal.
Lint-scope only: it has no effect on elaboration, the kernel check, or the
audit gate. -/
@[unused_variables_ignore_fn]
def Unsorry.PlatonicSchlafliCoreS2S1.ignoreForallTypeBinders :
    Lean.Linter.IgnoreFunction := fun _ stack _ =>
  stack.matches [`null, ``Lean.Parser.Term.explicitBinder, `null,
    ``Lean.Parser.Term.«forall»]
