import Mathlib

/-- Goal `geometric-series-ratio-seventyfour`: a geometric series with ratio 74 closed form, by induction on `n`. -/
theorem geometric_series_ratio_seventyfour (n : ℕ) : ((74 : ℤ) - 1) * ∑ k ∈ Finset.range n, (74 : ℤ) ^ k = (74 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
