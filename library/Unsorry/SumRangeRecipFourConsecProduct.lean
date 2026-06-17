import Mathlib

theorem sum_range_recip_four_consec_product (n : ℕ) : (∑ k ∈ Finset.range n, (1 : ℚ) / ((k + 1) * (k + 2) * (k + 3) * (k + 4))) = 1 / 18 - 1 / (3 * ((n : ℚ) + 1) * (n + 2) * (n + 3)) := by
  induction n with
  | zero => norm_num
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have h1 : ((m : ℚ) + 1) ≠ 0 := by positivity
    have h2 : ((m : ℚ) + 2) ≠ 0 := by positivity
    have h3 : ((m : ℚ) + 3) ≠ 0 := by positivity
    have h4 : ((m : ℚ) + 4) ≠ 0 := by positivity
    push_cast
    field_simp
    ring