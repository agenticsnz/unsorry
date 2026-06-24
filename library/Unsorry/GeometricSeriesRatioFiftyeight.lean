import Mathlib

/-- Goal `geometric-series-ratio-fiftyeight`: a geometric series with ratio 58 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fiftyeight (n : ℕ) : ((58 : ℤ) - 1) * ∑ k ∈ Finset.range n, (58 : ℤ) ^ k = (58 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
