import Mathlib

/-- Goal `geometric-series-ratio-twentyseven`: a geometric series with ratio 27 closed form, by induction on `n`. -/
theorem geometric_series_ratio_twentyseven (n : ℕ) : ((27 : ℤ) - 1) * ∑ k ∈ Finset.range n, (27 : ℤ) ^ k = (27 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
