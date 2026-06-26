import Mathlib

/-- Goal `geometric-series-ratio-thirtythree`: a geometric series with ratio 33 closed form, by induction on `n`. -/
theorem geometric_series_ratio_thirtythree (n : ℕ) : ((33 : ℤ) - 1) * ∑ k ∈ Finset.range n, (33 : ℤ) ^ k = (33 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
