import Mathlib

/-- Goal `geometric-series-ratio-seventyfive`: a geometric series with ratio 75 closed form, by induction on `n`. -/
theorem geometric_series_ratio_seventyfive (n : ℕ) : ((75 : ℤ) - 1) * ∑ k ∈ Finset.range n, (75 : ℤ) ^ k = (75 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
