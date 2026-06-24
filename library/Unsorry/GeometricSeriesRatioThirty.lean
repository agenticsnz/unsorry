import Mathlib

/-- Goal `geometric-series-ratio-thirty`: a geometric series with ratio 30 closed form, by induction on `n`. -/
theorem geometric_series_ratio_thirty (n : ℕ) : ((30 : ℤ) - 1) * ∑ k ∈ Finset.range n, (30 : ℤ) ^ k = (30 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
