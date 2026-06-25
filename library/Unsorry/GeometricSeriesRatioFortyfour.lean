import Mathlib

/-- Goal `geometric-series-ratio-fortyfour`: a geometric series with ratio 44 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fortyfour (n : ℕ) : ((44 : ℤ) - 1) * ∑ k ∈ Finset.range n, (44 : ℤ) ^ k = (44 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
