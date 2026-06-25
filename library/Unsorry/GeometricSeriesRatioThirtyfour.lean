import Mathlib

/-- Goal `geometric-series-ratio-thirtyfour`: a geometric series with ratio 34 closed form, by induction on `n`. -/
theorem geometric_series_ratio_thirtyfour (n : ℕ) : ((34 : ℤ) - 1) * ∑ k ∈ Finset.range n, (34 : ℤ) ^ k = (34 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
