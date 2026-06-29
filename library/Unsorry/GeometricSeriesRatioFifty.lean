import Mathlib

/-- Goal `geometric-series-ratio-fifty`: a geometric series with ratio 50 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fifty (n : ℕ) : ((50 : ℤ) - 1) * ∑ k ∈ Finset.range n, (50 : ℤ) ^ k = (50 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
