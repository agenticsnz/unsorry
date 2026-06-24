import Mathlib

/-- Goal `geometric-series-ratio-fortyfive`: a geometric series with ratio 45 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fortyfive (n : ℕ) : ((45 : ℤ) - 1) * ∑ k ∈ Finset.range n, (45 : ℤ) ^ k = (45 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
