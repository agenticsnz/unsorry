import Mathlib

/-- Goal `geometric-series-ratio-sixtythree`: a geometric series with ratio 63 closed form, by induction on `n`. -/
theorem geometric_series_ratio_sixtythree (n : ℕ) : ((63 : ℤ) - 1) * ∑ k ∈ Finset.range n, (63 : ℤ) ^ k = (63 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
