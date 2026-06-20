import Mathlib

theorem sum_icc_eight_k_div_odd_sq_pair_telescope (n : ℕ) : ∑ k ∈ Finset.Icc 1 n, (8 * (k : ℝ)) / (((2 * k - 1) ^ 2) * ((2 * k + 1) ^ 2)) = 1 - 1 / ((2 * (n : ℝ) + 1) ^ 2) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_Icc_succ_top (by omega), ih]
    push_cast
    have e1 : (2 * ((m : ℝ) + 1) - 1) = (2 * (m : ℝ) + 1) := by ring
    rw [e1]
    have h2 : (2 * ((m : ℝ) + 1) + 1) ^ 2 ≠ 0 := by positivity
    have h3 : (2 * (m : ℝ) + 1) ^ 2 ≠ 0 := by positivity
    field_simp
    ring
