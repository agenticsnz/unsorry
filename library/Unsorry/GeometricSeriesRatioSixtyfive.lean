import Mathlib

/-- Goal `geometric-series-ratio-sixtyfive`: a geometric series with ratio 65 closed form, by induction on `n`. -/
theorem geometric_series_ratio_sixtyfive (n : ℕ) : ((65 : ℤ) - 1) * ∑ k ∈ Finset.range n, (65 : ℤ) ^ k = (65 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
