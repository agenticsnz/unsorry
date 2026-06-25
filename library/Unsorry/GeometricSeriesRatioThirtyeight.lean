import Mathlib

/-- Goal `geometric-series-ratio-thirtyeight`: a geometric series with ratio 38 closed form, by induction on `n`. -/
theorem geometric_series_ratio_thirtyeight (n : ℕ) : ((38 : ℤ) - 1) * ∑ k ∈ Finset.range n, (38 : ℤ) ^ k = (38 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
