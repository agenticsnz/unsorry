import Mathlib

/-- Goal `geometric-series-ratio-twentyone`: a geometric series with ratio 21 closed form, by induction on `n`. -/
theorem geometric_series_ratio_twentyone (n : ℕ) : ((21 : ℤ) - 1) * ∑ k ∈ Finset.range n, (21 : ℤ) ^ k = (21 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
