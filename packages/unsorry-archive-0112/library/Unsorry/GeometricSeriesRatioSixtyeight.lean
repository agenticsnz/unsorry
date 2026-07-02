import Mathlib

/-- Goal `geometric-series-ratio-sixtyeight`: a geometric series with ratio 68 closed form, by induction on `n`. -/
theorem geometric_series_ratio_sixtyeight (n : ℕ) : ((68 : ℤ) - 1) * ∑ k ∈ Finset.range n, (68 : ℤ) ^ k = (68 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
