import Mathlib

/-- Goal `geometric-series-ratio-eighteen`: a geometric series with ratio 18 closed form, by induction on `n`. -/
theorem geometric_series_ratio_eighteen (n : ℕ) : ((18 : ℤ) - 1) * ∑ k ∈ Finset.range n, (18 : ℤ) ^ k = (18 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
