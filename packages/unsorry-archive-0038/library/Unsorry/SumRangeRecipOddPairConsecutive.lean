import Mathlib

theorem sum_range_recip_odd_pair_consecutive (n : ℕ) : ∑ k ∈ Finset.range n, (1 : ℚ) / ((2 * (k : ℚ) + 1) * (2 * (k : ℚ) + 3)) = (n : ℚ) / (2 * (n : ℚ) + 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    push_cast
    have h1 : (2 * (m : ℚ) + 1) ≠ 0 := by positivity
    have h2 : (2 * (m : ℚ) + 3) ≠ 0 := by positivity
    have h3 : (2 * ((m : ℚ) + 1) + 1) ≠ 0 := by positivity
    field_simp
    ring