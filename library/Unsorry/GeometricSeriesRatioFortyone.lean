import Mathlib

/-- Goal `geometric-series-ratio-fortyone`: a geometric series with ratio 41 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fortyone (n : ℕ) : ((41 : ℤ) - 1) * ∑ k ∈ Finset.range n, (41 : ℤ) ^ k = (41 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
