import Mathlib

/-- Goal `geometric-series-ratio-seventeen`: a geometric series with ratio 17 closed form, by induction on `n`. -/
theorem geometric_series_ratio_seventeen (n : ℕ) : ((17 : ℤ) - 1) * ∑ k ∈ Finset.range n, (17 : ℤ) ^ k = (17 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
