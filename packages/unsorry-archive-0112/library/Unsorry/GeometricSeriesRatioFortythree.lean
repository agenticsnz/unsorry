import Mathlib

/-- Goal `geometric-series-ratio-fortythree`: a geometric series with ratio 43 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fortythree (n : ℕ) : ((43 : ℤ) - 1) * ∑ k ∈ Finset.range n, (43 : ℤ) ^ k = (43 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
