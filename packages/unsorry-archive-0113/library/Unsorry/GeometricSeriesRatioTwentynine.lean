import Mathlib

/-- Goal `geometric-series-ratio-twentynine`: a geometric series with ratio 29 closed form, by induction on `n`. -/
theorem geometric_series_ratio_twentynine (n : ℕ) : ((29 : ℤ) - 1) * ∑ k ∈ Finset.range n, (29 : ℤ) ^ k = (29 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
