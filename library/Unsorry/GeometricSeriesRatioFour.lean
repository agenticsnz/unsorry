import Mathlib

/-- Goal `geometric-series-ratio-four`: a geometric series with ratio 4 closed form, by induction on `n`. -/
theorem geometric_series_ratio_four (n : ℕ) : ((4 : ℤ) - 1) * ∑ k ∈ Finset.range n, (4 : ℤ) ^ k = (4 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
