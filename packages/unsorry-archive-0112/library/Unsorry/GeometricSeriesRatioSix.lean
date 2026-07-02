import Mathlib

/-- Goal `geometric-series-ratio-six`: a geometric series with ratio 6 closed form, by induction on `n`. -/
theorem geometric_series_ratio_six (n : ℕ) : ((6 : ℤ) - 1) * ∑ k ∈ Finset.range n, (6 : ℤ) ^ k = (6 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
