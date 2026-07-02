import Mathlib

/-- Goal `geometric-series-ratio-fortytwo`: a geometric series with ratio 42 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fortytwo (n : ℕ) : ((42 : ℤ) - 1) * ∑ k ∈ Finset.range n, (42 : ℤ) ^ k = (42 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
