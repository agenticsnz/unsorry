import Mathlib

/-- Goal `geometric-series-ratio-thirtyone`: a geometric series with ratio 31 closed form, by induction on `n`. -/
theorem geometric_series_ratio_thirtyone (n : ℕ) : ((31 : ℤ) - 1) * ∑ k ∈ Finset.range n, (31 : ℤ) ^ k = (31 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
