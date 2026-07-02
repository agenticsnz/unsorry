import Mathlib

/-- Goal `geometric-series-ratio-thirtyseven`: a geometric series with ratio 37 closed form, by induction on `n`. -/
theorem geometric_series_ratio_thirtyseven (n : ℕ) : ((37 : ℤ) - 1) * ∑ k ∈ Finset.range n, (37 : ℤ) ^ k = (37 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
