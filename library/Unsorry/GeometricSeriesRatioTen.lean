import Mathlib

/-- Goal `geometric-series-ratio-ten`: a geometric series with ratio 10 closed form, by induction on `n`. -/
theorem geometric_series_ratio_ten (n : ℕ) : ((10 : ℤ) - 1) * ∑ k ∈ Finset.range n, (10 : ℤ) ^ k = (10 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
