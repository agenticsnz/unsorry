import Mathlib

/-- Goal `geometric-series-ratio-sixtyfour`: a geometric series with ratio 64 closed form, by induction on `n`. -/
theorem geometric_series_ratio_sixtyfour (n : ℕ) : ((64 : ℤ) - 1) * ∑ k ∈ Finset.range n, (64 : ℤ) ^ k = (64 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
