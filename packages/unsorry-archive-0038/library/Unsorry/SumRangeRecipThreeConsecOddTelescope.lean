import Mathlib

theorem sum_range_recip_three_consec_odd_telescope (n : ℕ) : (∑ k ∈ Finset.range n, (1 : ℚ) / ((2 * k + 1) * (2 * k + 3) * (2 * k + 5))) = 1 / 12 - 1 / (4 * (2 * (n : ℚ) + 1) * (2 * n + 3)) := by
  induction n with
  | zero => norm_num
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    push_cast
    have h1 : (2 * (m : ℚ) + 1) ≠ 0 := by positivity
    have h2 : (2 * (m : ℚ) + 3) ≠ 0 := by positivity
    have h3 : (2 * (m : ℚ) + 5) ≠ 0 := by positivity
    field_simp
    ring