import Mathlib

/-- Goal `geometric-series-ratio-sixtyseven`: a geometric series with ratio 67 closed form, by induction on `n`. -/
theorem geometric_series_ratio_sixtyseven (n : ℕ) : ((67 : ℤ) - 1) * ∑ k ∈ Finset.range n, (67 : ℤ) ^ k = (67 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
