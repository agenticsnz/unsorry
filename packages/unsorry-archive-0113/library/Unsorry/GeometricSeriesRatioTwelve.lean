import Mathlib

/-- Goal `geometric-series-ratio-twelve`: a geometric series with ratio 12 closed form, by induction on `n`. -/
theorem geometric_series_ratio_twelve (n : ℕ) : ((12 : ℤ) - 1) * ∑ k ∈ Finset.range n, (12 : ℤ) ^ k = (12 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
