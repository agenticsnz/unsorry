import Mathlib

/-- Goal `geometric-series-ratio-nine`: a geometric series with ratio 9 closed form, by induction on `n`. -/
theorem geometric_series_ratio_nine (n : ℕ) : ((9 : ℤ) - 1) * ∑ k ∈ Finset.range n, (9 : ℤ) ^ k = (9 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
