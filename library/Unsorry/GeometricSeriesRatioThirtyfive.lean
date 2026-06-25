import Mathlib

/-- Goal `geometric-series-ratio-thirtyfive`: a geometric series with ratio 35 closed form, by induction on `n`. -/
theorem geometric_series_ratio_thirtyfive (n : ℕ) : ((35 : ℤ) - 1) * ∑ k ∈ Finset.range n, (35 : ℤ) ^ k = (35 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
