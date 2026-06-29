import Mathlib

/-- Goal `geometric-series-ratio-eleven`: a geometric series with ratio 11 closed form, by induction on `n`. -/
theorem geometric_series_ratio_eleven (n : ℕ) : ((11 : ℤ) - 1) * ∑ k ∈ Finset.range n, (11 : ℤ) ^ k = (11 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
