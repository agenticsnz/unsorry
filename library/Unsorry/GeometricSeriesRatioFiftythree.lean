import Mathlib

/-- Goal `geometric-series-ratio-fiftythree`: a geometric series with ratio 53 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fiftythree (n : ℕ) : ((53 : ℤ) - 1) * ∑ k ∈ Finset.range n, (53 : ℤ) ^ k = (53 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
