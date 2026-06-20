import Mathlib

theorem sum_one_div_succ_mul_add_four_telescope (n : ℕ) : (∑ k ∈ Finset.range n, (3 : ℚ) / ((k + 1) * (k + 4))) = 11 / 6 - 1 / ((n : ℚ) + 1) - 1 / (n + 2) - 1 / (n + 3) := by
  induction n with
  | zero => norm_num
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    push_cast
    have h1 : ((m : ℚ) + 1) ≠ 0 := by positivity
    have h2 : ((m : ℚ) + 2) ≠ 0 := by positivity
    have h3 : ((m : ℚ) + 3) ≠ 0 := by positivity
    have h4 : ((m : ℚ) + 4) ≠ 0 := by positivity
    field_simp
    ring