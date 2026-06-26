import Mathlib

/-- Goal `geometric-series-ratio-fortysix`: a geometric series with ratio 46 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fortysix (n : ℕ) : ((46 : ℤ) - 1) * ∑ k ∈ Finset.range n, (46 : ℤ) ^ k = (46 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
