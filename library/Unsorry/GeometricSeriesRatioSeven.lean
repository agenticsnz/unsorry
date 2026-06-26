import Mathlib

/-- Goal `geometric-series-ratio-seven`: a geometric series with ratio 7 closed form, by induction on `n`. -/
theorem geometric_series_ratio_seven (n : ℕ) : ((7 : ℤ) - 1) * ∑ k ∈ Finset.range n, (7 : ℤ) ^ k = (7 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
