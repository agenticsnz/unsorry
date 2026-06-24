import Mathlib

/-- Goal `geometric-series-ratio-sixteen`: a geometric series with ratio 16 closed form, by induction on `n`. -/
theorem geometric_series_ratio_sixteen (n : ℕ) : ((16 : ℤ) - 1) * ∑ k ∈ Finset.range n, (16 : ℤ) ^ k = (16 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
