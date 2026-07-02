import Mathlib

/-- Goal `geometric-series-ratio-two`: a geometric series with ratio 2 closed form, by induction on `n`. -/
theorem geometric_series_ratio_two (n : ℕ) : ((2 : ℤ) - 1) * ∑ k ∈ Finset.range n, (2 : ℤ) ^ k = (2 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
