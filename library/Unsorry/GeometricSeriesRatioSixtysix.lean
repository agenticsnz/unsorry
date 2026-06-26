import Mathlib

/-- Goal `geometric-series-ratio-sixtysix`: a geometric series with ratio 66 closed form, by induction on `n`. -/
theorem geometric_series_ratio_sixtysix (n : ℕ) : ((66 : ℤ) - 1) * ∑ k ∈ Finset.range n, (66 : ℤ) ^ k = (66 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
