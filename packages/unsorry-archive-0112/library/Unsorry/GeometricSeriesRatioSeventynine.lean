import Mathlib

/-- Goal `geometric-series-ratio-seventynine`: a geometric series with ratio 79 closed form, by induction on `n`. -/
theorem geometric_series_ratio_seventynine (n : ℕ) : ((79 : ℤ) - 1) * ∑ k ∈ Finset.range n, (79 : ℤ) ^ k = (79 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
