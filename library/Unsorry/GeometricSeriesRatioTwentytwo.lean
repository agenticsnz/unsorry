import Mathlib

/-- Goal `geometric-series-ratio-twentytwo`: a geometric series with ratio 22 closed form, by induction on `n`. -/
theorem geometric_series_ratio_twentytwo (n : ℕ) : ((22 : ℤ) - 1) * ∑ k ∈ Finset.range n, (22 : ℤ) ^ k = (22 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
