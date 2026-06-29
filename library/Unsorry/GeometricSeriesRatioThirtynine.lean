import Mathlib

/-- Goal `geometric-series-ratio-thirtynine`: a geometric series with ratio 39 closed form, by induction on `n`. -/
theorem geometric_series_ratio_thirtynine (n : ℕ) : ((39 : ℤ) - 1) * ∑ k ∈ Finset.range n, (39 : ℤ) ^ k = (39 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
