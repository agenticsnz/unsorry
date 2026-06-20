import Mathlib

theorem sum_range_recip_odd_product (n : ℕ) :
    ∑ k ∈ Finset.range n, (1 : ℚ) / ((2 * k + 1) * (2 * k + 3)) = n / (2 * n + 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have h1 : (2 * (m : ℚ) + 1) ≠ 0 := by positivity
    have h2 : (2 * (m : ℚ) + 3) ≠ 0 := by positivity
    have h3 : (2 * (m : ℚ) + 1) ≠ 0 := by positivity
    push_cast
    field_simp
    ring