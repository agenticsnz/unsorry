import Mathlib

/-- Goal `geometric-series-ratio-twentyfour`: a geometric series with ratio 24 closed form, by induction on `n`. -/
theorem geometric_series_ratio_twentyfour (n : ℕ) : ((24 : ℤ) - 1) * ∑ k ∈ Finset.range n, (24 : ℤ) ^ k = (24 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
