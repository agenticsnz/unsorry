import Mathlib

/-- Goal `geometric-series-ratio-seventytwo`: a geometric series with ratio 72 closed form, by induction on `n`. -/
theorem geometric_series_ratio_seventytwo (n : ℕ) : ((72 : ℤ) - 1) * ∑ k ∈ Finset.range n, (72 : ℤ) ^ k = (72 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
