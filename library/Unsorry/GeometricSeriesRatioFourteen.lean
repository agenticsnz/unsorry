import Mathlib

/-- Goal `geometric-series-ratio-fourteen`: a geometric series with ratio 14 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fourteen (n : ℕ) : ((14 : ℤ) - 1) * ∑ k ∈ Finset.range n, (14 : ℤ) ^ k = (14 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
