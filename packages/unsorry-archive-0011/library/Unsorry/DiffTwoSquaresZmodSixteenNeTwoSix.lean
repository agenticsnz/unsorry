import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic

/-!
# Difference of two squares modulo sixteen

A difference of two integer squares is never congruent to `2`, `6`, `10`, or `14`
modulo `16`.  Each branch reduces the congruence to an equation in the finite ring
`ZMod 16`, where the finitely many cases are checked by `decide`.
-/

theorem diff_two_squares_zmod_sixteen_ne_two_six (a b : ℤ) :
    ¬ (a ^ 2 - b ^ 2 ≡ 2 [ZMOD 16]) ∧ ¬ (a ^ 2 - b ^ 2 ≡ 6 [ZMOD 16]) ∧
      ¬ (a ^ 2 - b ^ 2 ≡ 10 [ZMOD 16]) ∧ ¬ (a ^ 2 - b ^ 2 ≡ 14 [ZMOD 16]) := by
  have key : ∀ x y : ZMod 16,
      x ^ 2 - y ^ 2 ≠ 2 ∧ x ^ 2 - y ^ 2 ≠ 6 ∧
        x ^ 2 - y ^ 2 ≠ 10 ∧ x ^ 2 - y ^ 2 ≠ 14 := by decide
  obtain ⟨h2, h6, h10, h14⟩ := key (a : ZMod 16) (b : ZMod 16)
  refine ⟨fun h => h2 ?_, fun h => h6 ?_, fun h => h10 ?_, fun h => h14 ?_⟩ <;>
    · have hc := (ZMod.intCast_eq_intCast_iff _ _ _).mpr h
      push_cast at hc
      exact hc
