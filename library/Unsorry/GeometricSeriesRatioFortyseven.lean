import Mathlib

/-- Goal `geometric-series-ratio-fortyseven`: a geometric series with ratio 47 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fortyseven (n : ℕ) : ((47 : ℤ) - 1) * ∑ k ∈ Finset.range n, (47 : ℤ) ^ k = (47 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
