import Mathlib

/-- Goal `geometric-series-ratio-nineteen`: a geometric series with ratio 19 closed form, by induction on `n`. -/
theorem geometric_series_ratio_nineteen (n : ℕ) : ((19 : ℤ) - 1) * ∑ k ∈ Finset.range n, (19 : ℤ) ^ k = (19 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
