import Mathlib

/-- Goal `geometric-series-ratio-fiftyone`: a geometric series with ratio 51 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fiftyone (n : ℕ) : ((51 : ℤ) - 1) * ∑ k ∈ Finset.range n, (51 : ℤ) ^ k = (51 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
