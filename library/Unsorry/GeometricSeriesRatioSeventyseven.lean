import Mathlib

/-- Goal `geometric-series-ratio-seventyseven`: a geometric series with ratio 77 closed form, by induction on `n`. -/
theorem geometric_series_ratio_seventyseven (n : ℕ) : ((77 : ℤ) - 1) * ∑ k ∈ Finset.range n, (77 : ℤ) ^ k = (77 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
