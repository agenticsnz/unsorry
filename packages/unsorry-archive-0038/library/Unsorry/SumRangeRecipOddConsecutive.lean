import Mathlib

theorem sum_range_recip_odd_consecutive (n : ℕ) : ∑ k ∈ Finset.range n, (1 : ℝ) / ((2*k+1)*(2*k+3)) = n / (2*n+1) := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [Finset.sum_range_succ, ih]
    have h1 : (2 * (n:ℝ) + 1) ≠ 0 := by positivity
    have h2 : (2 * (n:ℝ) + 3) ≠ 0 := by positivity
    have h3 : (2 * ((n:ℝ)+1) + 1) ≠ 0 := by positivity
    push_cast
    field_simp
    ring