import Mathlib

/-- Goal `geometric-series-ratio-forty`: a geometric series with ratio 40 closed form, by induction on `n`. -/
theorem geometric_series_ratio_forty (n : ℕ) : ((40 : ℤ) - 1) * ∑ k ∈ Finset.range n, (40 : ℤ) ^ k = (40 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
