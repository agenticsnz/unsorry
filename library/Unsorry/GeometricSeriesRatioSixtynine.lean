import Mathlib

/-- Goal `geometric-series-ratio-sixtynine`: a geometric series with ratio 69 closed form, by induction on `n`. -/
theorem geometric_series_ratio_sixtynine (n : ℕ) : ((69 : ℤ) - 1) * ∑ k ∈ Finset.range n, (69 : ℤ) ^ k = (69 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
