import Mathlib

theorem sum_range_recip_consecutive (n : ℕ) :
    ∑ k ∈ Finset.range n, (1 : ℚ) / ((k + 1) * (k + 2)) = n / (n + 1) := by
  induction n with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ih]
    have h1 : (m : ℚ) + 1 ≠ 0 := by positivity
    have h2 : (m : ℚ) + 2 ≠ 0 := by positivity
    push_cast
    field_simp
    ring