import Mathlib

/-- Goal `geometric-series-ratio-thirtytwo`: a geometric series with ratio 32 closed form, by induction on `n`. -/
theorem geometric_series_ratio_thirtytwo (n : ℕ) : ((32 : ℤ) - 1) * ∑ k ∈ Finset.range n, (32 : ℤ) ^ k = (32 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
