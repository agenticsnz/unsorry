import Mathlib

/-- Goal `geometric-series-ratio-seventysix`: a geometric series with ratio 76 closed form, by induction on `n`. -/
theorem geometric_series_ratio_seventysix (n : ℕ) : ((76 : ℤ) - 1) * ∑ k ∈ Finset.range n, (76 : ℤ) ^ k = (76 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
