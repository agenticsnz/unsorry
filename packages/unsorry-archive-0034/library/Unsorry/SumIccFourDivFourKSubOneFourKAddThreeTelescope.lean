import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Tactic

open scoped BigOperators

theorem sum_icc_four_div_four_k_sub_one_four_k_add_three_telescope (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n, (4 : ℚ) / ((4 * (k : ℚ) - 1) * (4 * (k : ℚ) + 3)) =
      1 / 3 - 1 / (4 * (n : ℚ) + 3) := by
  induction n with
  | zero =>
      norm_num
  | succ n ih =>
      rw [Finset.sum_Icc_succ_top (by omega)]
      rw [ih]
      have hsucc₁ : 4 * ((Nat.succ n : ℕ) : ℚ) - 1 = 4 * (n : ℚ) + 3 := by
        norm_num [Nat.cast_succ]
        ring
      have hsucc₂ : 4 * ((Nat.succ n : ℕ) : ℚ) + 3 = 4 * (n : ℚ) + 7 := by
        norm_num [Nat.cast_succ]
        ring
      rw [hsucc₁, hsucc₂]
      have h₁ : (4 * (n : ℚ) + 3) ≠ 0 := by positivity
      have h₂ : (4 * (n : ℚ) + 7) ≠ 0 := by positivity
      field_simp [h₁, h₂]
      ring
