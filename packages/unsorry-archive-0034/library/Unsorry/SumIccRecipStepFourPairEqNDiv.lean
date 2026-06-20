import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Real.Basic
import Mathlib.Tactic

open scoped BigOperators

theorem sum_icc_recip_step_four_pair_eq_n_div (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n, (1 : ℝ) / ((4 * k - 3) * (4 * k + 1)) =
      n / (4 * n + 1) := by
  induction n with
  | zero =>
      simp
  | succ n ih =>
      rw [Finset.sum_Icc_succ_top]
      · rw [ih]
        simp only [Nat.cast_succ]
        have hsub : 4 * ((n : ℝ) + 1) - 3 = 4 * (n : ℝ) + 1 := by ring
        have hadd : 4 * ((n : ℝ) + 1) + 1 = 4 * (n : ℝ) + 5 := by ring
        rw [hsub, hadd]
        have h1 : (4 * (n : ℝ) + 1) ≠ 0 := by positivity
        have h5 : (4 * (n : ℝ) + 5) ≠ 0 := by positivity
        field_simp [h1, h5]
        ring
      · omega
