import Mathlib

/-- Goal `geometric-series-ratio-fiftyfive`: a geometric series with ratio 55 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fiftyfive (n : ℕ) : ((55 : ℤ) - 1) * ∑ k ∈ Finset.range n, (55 : ℤ) ^ k = (55 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
