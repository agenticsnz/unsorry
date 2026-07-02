import Mathlib

/-- Goal `geometric-series-ratio-fortyeight`: a geometric series with ratio 48 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fortyeight (n : ℕ) : ((48 : ℤ) - 1) * ∑ k ∈ Finset.range n, (48 : ℤ) ^ k = (48 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
