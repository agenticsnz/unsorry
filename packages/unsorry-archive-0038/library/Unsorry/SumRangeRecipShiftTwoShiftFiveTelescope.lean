import Mathlib

theorem sum_range_recip_shift_two_shift_five_telescope (n : ℕ) : ∑ k ∈ Finset.range n, (3 : ℚ) / (((k : ℚ) + 2) * ((k : ℚ) + 5)) = 13 / 12 - 1 / ((n : ℚ) + 2) - 1 / ((n : ℚ) + 3) - 1 / ((n : ℚ) + 4) := by
  induction n with
  | zero => norm_num
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have h2 : ((m : ℚ) + 2) ≠ 0 := by positivity
    have h3 : ((m : ℚ) + 3) ≠ 0 := by positivity
    have h4 : ((m : ℚ) + 4) ≠ 0 := by positivity
    have h5 : ((m : ℚ) + 5) ≠ 0 := by positivity
    push_cast
    field_simp
    ring