import Mathlib

theorem sum_range_odd_num_sq_succ_sq_telescope (n : ℕ) : ∑ k ∈ Finset.range n, (2 * (k : ℚ) + 3) / ((((k : ℚ) + 1) ^ 2) * (((k : ℚ) + 2) ^ 2)) = 1 - 1 / (((n : ℚ) + 1) ^ 2) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    push_cast
    have h1 : ((m : ℚ) + 1) ^ 2 ≠ 0 := by positivity
    have h2 : ((m : ℚ) + 2) ^ 2 ≠ 0 := by positivity
    field_simp
    ring