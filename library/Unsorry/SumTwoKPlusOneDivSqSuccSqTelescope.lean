import Mathlib

theorem sum_two_k_plus_one_div_sq_succ_sq_telescope (n : ℕ) : (∑ k ∈ Finset.range n, (2 * (k + 1) + 1) / (((k + 1) : ℚ) ^ 2 * (k + 2) ^ 2)) = 1 - 1 / ((n : ℚ) + 1) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    push_cast
    have h1 : ((m : ℚ) + 1) ≠ 0 := by positivity
    have h2 : ((m : ℚ) + 2) ≠ 0 := by positivity
    field_simp
    ring