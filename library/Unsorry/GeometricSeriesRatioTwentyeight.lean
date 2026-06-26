import Mathlib

/-- Goal `geometric-series-ratio-twentyeight`: a geometric series with ratio 28 closed form, by induction on `n`. -/
theorem geometric_series_ratio_twentyeight (n : ℕ) : ((28 : ℤ) - 1) * ∑ k ∈ Finset.range n, (28 : ℤ) ^ k = (28 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
