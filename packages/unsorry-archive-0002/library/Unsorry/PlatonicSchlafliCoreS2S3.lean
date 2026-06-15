import Lean.Linter.UnusedVariables
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Algebra.Order.GroupWithZero.Unbundled.Basic
import Mathlib.Tactic.NormNum

/-!
# `nat_lt_six_of_sixth_lt_inv` (goal `platonic-schlafli-core-s2-s3`)

For a natural `p`, if `(6 : ℚ)⁻¹ < (p : ℚ)⁻¹` then `p < 6`. Contrapositive:
if `6 ≤ p` then `(6 : ℚ) ≤ (p : ℚ)`, and inversion is antitone on the
positives (`inv_anti₀`), so `(p : ℚ)⁻¹ ≤ (6 : ℚ)⁻¹`, contradicting the strict
inequality. (The `p = 0` case never arises here: `(0 : ℚ)⁻¹ = 0` is not
greater than `6⁻¹`, so the hypothesis already forces `p` positive.)
-/

theorem nat_lt_six_of_sixth_lt_inv (p : ℕ) (h : (6 : ℚ)⁻¹ < (p : ℚ)⁻¹) : p < 6 := by
  by_contra hle
  have h6 : (6 : ℚ) ≤ (p : ℚ) := by exact_mod_cast Nat.le_of_not_lt hle
  exact lt_irrefl ((6 : ℚ)⁻¹) (h.trans_le (inv_anti₀ (by norm_num) h6))

/-- The ADR-011 binding obligation that Gate A regenerates for this goal states
its type as `∀ (p : ℕ) (h : (6 : ℚ)⁻¹ < (p : ℚ)⁻¹), p < 6`, copying the goal's
binder names verbatim. `h` does not occur in the conclusion, so the
unused-variables linter warns on it and the `--wfail` bar fails — in a
generated file this module cannot edit. Core Lean already exempts unused
binders in the arrow spelling `(h : P) → Q` of the same type (its builtin
`depArrow` ignore function), because a binder name there is signature
documentation; this extends that exemption to the `∀ (h : P), Q` spelling.
Lint-scope only: it has no effect on elaboration, the kernel check, or the
audit gate. -/
@[unused_variables_ignore_fn]
def Unsorry.PlatonicSchlafliCoreS2S3.ignoreForallTypeBinders :
    Lean.Linter.IgnoreFunction := fun _ stack _ =>
  stack.matches [`null, ``Lean.Parser.Term.explicitBinder, `null,
    ``Lean.Parser.Term.«forall»]
