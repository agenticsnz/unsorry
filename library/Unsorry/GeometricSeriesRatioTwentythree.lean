import Mathlib

/-- Goal `geometric-series-ratio-twentythree`: a geometric series with ratio 23 closed form, by induction on `n`. -/
theorem geometric_series_ratio_twentythree (n : ℕ) : ((23 : ℤ) - 1) * ∑ k ∈ Finset.range n, (23 : ℤ) ^ k = (23 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
