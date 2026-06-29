import Mathlib

theorem sum_range_recip_five_step_product (n : ℕ) : ∑ k ∈ Finset.range n, (1 : ℚ) / ((5 * (k : ℚ) + 2) * (5 * (k : ℚ) + 7)) = (n : ℚ) / (2 * (5 * (n : ℚ) + 2)) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have h1 : (5 * (m : ℚ) + 2) ≠ 0 := by positivity
    have h2 : (5 * (m : ℚ) + 7) ≠ 0 := by positivity
    have h3 : (5 * ((m : ℚ) + 1) + 2) ≠ 0 := by positivity
    push_cast
    field_simp
    ring