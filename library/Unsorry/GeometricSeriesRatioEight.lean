import Mathlib

/-- Goal `geometric-series-ratio-eight`: a geometric series with ratio 8 closed form, by induction on `n`. -/
theorem geometric_series_ratio_eight (n : ℕ) : ((8 : ℤ) - 1) * ∑ k ∈ Finset.range n, (8 : ℤ) ^ k = (8 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
