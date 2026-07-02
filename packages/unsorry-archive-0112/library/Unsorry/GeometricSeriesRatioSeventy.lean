import Mathlib

/-- Goal `geometric-series-ratio-seventy`: a geometric series with ratio 70 closed form, by induction on `n`. -/
theorem geometric_series_ratio_seventy (n : ℕ) : ((70 : ℤ) - 1) * ∑ k ∈ Finset.range n, (70 : ℤ) ^ k = (70 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
