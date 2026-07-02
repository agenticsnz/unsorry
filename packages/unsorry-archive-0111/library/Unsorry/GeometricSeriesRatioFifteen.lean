import Mathlib

/-- Goal `geometric-series-ratio-fifteen`: a geometric series with ratio 15 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fifteen (n : ℕ) : ((15 : ℤ) - 1) * ∑ k ∈ Finset.range n, (15 : ℤ) ^ k = (15 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
