import Mathlib

/-- Goal `geometric-series-ratio-fiftyseven`: a geometric series with ratio 57 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fiftyseven (n : ℕ) : ((57 : ℤ) - 1) * ∑ k ∈ Finset.range n, (57 : ℤ) ^ k = (57 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
