import Mathlib

/-- Goal `geometric-series-ratio-fiftytwo`: a geometric series with ratio 52 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fiftytwo (n : ℕ) : ((52 : ℤ) - 1) * ∑ k ∈ Finset.range n, (52 : ℤ) ^ k = (52 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
