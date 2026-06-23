import Mathlib

/-- Goal `geometric-series-ratio-sixtyone`: a geometric series with ratio 61 closed form, by induction on `n`. -/
theorem geometric_series_ratio_sixtyone (n : ℕ) : ((61 : ℤ) - 1) * ∑ k ∈ Finset.range n, (61 : ℤ) ^ k = (61 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
