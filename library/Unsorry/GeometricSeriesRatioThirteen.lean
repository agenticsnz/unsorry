import Mathlib

/-- Goal `geometric-series-ratio-thirteen`: a geometric series with ratio 13 closed form, by induction on `n`. -/
theorem geometric_series_ratio_thirteen (n : ℕ) : ((13 : ℤ) - 1) * ∑ k ∈ Finset.range n, (13 : ℤ) ^ k = (13 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
