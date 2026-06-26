import Mathlib

/-- Goal `geometric-series-ratio-twentyfive`: a geometric series with ratio 25 closed form, by induction on `n`. -/
theorem geometric_series_ratio_twentyfive (n : ℕ) : ((25 : ℤ) - 1) * ∑ k ∈ Finset.range n, (25 : ℤ) ^ k = (25 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
