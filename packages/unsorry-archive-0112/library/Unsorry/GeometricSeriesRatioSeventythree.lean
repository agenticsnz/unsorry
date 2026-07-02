import Mathlib

/-- Goal `geometric-series-ratio-seventythree`: a geometric series with ratio 73 closed form, by induction on `n`. -/
theorem geometric_series_ratio_seventythree (n : ℕ) : ((73 : ℤ) - 1) * ∑ k ∈ Finset.range n, (73 : ℤ) ^ k = (73 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
