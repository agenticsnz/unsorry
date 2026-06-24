import Mathlib

/-- Goal `geometric-series-ratio-seventyeight`: a geometric series with ratio 78 closed form, by induction on `n`. -/
theorem geometric_series_ratio_seventyeight (n : ℕ) : ((78 : ℤ) - 1) * ∑ k ∈ Finset.range n, (78 : ℤ) ^ k = (78 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
