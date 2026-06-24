import Mathlib

/-- Goal `geometric-series-ratio-five`: a geometric series with ratio 5 closed form, by induction on `n`. -/
theorem geometric_series_ratio_five (n : ℕ) : ((5 : ℤ) - 1) * ∑ k ∈ Finset.range n, (5 : ℤ) ^ k = (5 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
