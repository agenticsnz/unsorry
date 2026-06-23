import Mathlib

/-- Goal `geometric-series-ratio-twenty`: a geometric series with ratio 20 closed form, by induction on `n`. -/
theorem geometric_series_ratio_twenty (n : ℕ) : ((20 : ℤ) - 1) * ∑ k ∈ Finset.range n, (20 : ℤ) ^ k = (20 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
