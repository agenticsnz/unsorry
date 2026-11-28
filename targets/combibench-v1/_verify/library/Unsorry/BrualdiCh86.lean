import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring.Basic

/-! Induct on the upper bound, add the final summand, and verify the polynomial identity. -/

theorem brualdi_ch8_6 (n : ℕ) (h : ℕ → ℝ) (h' : ∀ i, h i = 2 * i ^ 2 - i + 3) :
    ∑ i ∈ Finset.range (n + 1), h i = ((fun n => ((n + 1) * (4 * n ^ 2 - n + 18) / 6)) : ℕ → ℝ ) n := by
  induction n with
  | zero => norm_num [h']
  | succ n ih =>
      rw [Finset.sum_range_succ, ih, h']
      simp only [Nat.cast_succ]
      ring1
