import Mathlib

/-- Goal `geometric-series-ratio-sixty`: a geometric series with ratio 60 closed form, by induction on `n`. -/
theorem geometric_series_ratio_sixty (n : ℕ) : ((60 : ℤ) - 1) * ∑ k ∈ Finset.range n, (60 : ℤ) ^ k = (60 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
