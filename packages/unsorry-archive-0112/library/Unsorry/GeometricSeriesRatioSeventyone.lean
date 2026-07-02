import Mathlib

/-- Goal `geometric-series-ratio-seventyone`: a geometric series with ratio 71 closed form, by induction on `n`. -/
theorem geometric_series_ratio_seventyone (n : ℕ) : ((71 : ℤ) - 1) * ∑ k ∈ Finset.range n, (71 : ℤ) ^ k = (71 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
