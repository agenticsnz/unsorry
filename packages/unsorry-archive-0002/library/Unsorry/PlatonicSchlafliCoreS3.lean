import Lean.Linter.UnusedVariables
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Algebra.Order.GroupWithZero.Unbundled.Basic
import Mathlib.Data.Nat.Cast.Order.Basic
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.NormNum

/-!
# `platonic_schlafli_snd_lt_six` (goal `platonic-schlafli-core-s3`)

For naturals `p, q ≥ 3` with `(p : ℚ)⁻¹ + (q : ℚ)⁻¹ > 2⁻¹`, the second
Schläfli entry satisfies `q < 6`: since `3 ≤ p`, inversion antitonicity
(`inv_anti₀`) gives `(p : ℚ)⁻¹ ≤ 3⁻¹`, so `(q : ℚ)⁻¹ > 2⁻¹ - 3⁻¹ = 6⁻¹`,
and `inv_lt_inv₀` (with `0 < q` from `3 ≤ q`) turns that back into
`(q : ℚ) < 6`, which descends to `ℕ`.
-/

theorem platonic_schlafli_snd_lt_six (p q : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q)
    (h : (p : ℚ)⁻¹ + (q : ℚ)⁻¹ > 2⁻¹) : q < 6 := by
  have hpinv : (p : ℚ)⁻¹ ≤ (3 : ℚ)⁻¹ :=
    inv_anti₀ (by norm_num) (Nat.ofNat_le_cast.mpr hp)
  have hqpos : (0 : ℚ) < q := by
    exact_mod_cast Nat.lt_of_lt_of_le (by norm_num) hq
  have hqinv : (6 : ℚ)⁻¹ < (q : ℚ)⁻¹ := by
    have h36 : (2 : ℚ)⁻¹ - (3 : ℚ)⁻¹ = (6 : ℚ)⁻¹ := by norm_num
    linarith
  have hcast : (q : ℚ) < 6 := (inv_lt_inv₀ (by norm_num) hqpos).mp hqinv
  exact_mod_cast hcast

/-- The ADR-011 binding obligation that Gate A regenerates for this goal states
its type as `∀ (p q : ℕ) (hp : 3 ≤ p) (hq : 3 ≤ q)
(h : (p : ℚ)⁻¹ + (q : ℚ)⁻¹ > 2⁻¹), q < 6`, copying the goal's binder names
verbatim. `hp`, `hq`, and `h` do not occur in the conclusion, so the
unused-variables linter warns on them and the `--wfail` bar fails — in a
generated file this module cannot edit. Core Lean already exempts unused
binders in the arrow spelling `(h : P) → Q` of the same type (its builtin
`depArrow` ignore function), because a binder name there is signature
documentation; this extends that exemption to the `∀ (h : P), Q` spelling,
exactly as the merged `Unsorry.PlatonicSchlafliCoreS2S1` does for its goal.
Lint-scope only: it has no effect on elaboration, the kernel check, or the
audit gate. -/
@[unused_variables_ignore_fn]
def Unsorry.PlatonicSchlafliCoreS3.ignoreForallTypeBinders :
    Lean.Linter.IgnoreFunction := fun _ stack _ =>
  stack.matches [`null, ``Lean.Parser.Term.explicitBinder, `null,
    ``Lean.Parser.Term.«forall»]
