import Mathlib

/-- Goal `geometric-series-ratio-eighty`: a geometric series with ratio 80 closed form, by induction on `n`. -/
theorem geometric_series_ratio_eighty (n : ℕ) : ((80 : ℤ) - 1) * ∑ k ∈ Finset.range n, (80 : ℤ) ^ k = (80 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
