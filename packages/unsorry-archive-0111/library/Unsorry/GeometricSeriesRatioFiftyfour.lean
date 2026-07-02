import Mathlib

/-- Goal `geometric-series-ratio-fiftyfour`: a geometric series with ratio 54 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fiftyfour (n : ℕ) : ((54 : ℤ) - 1) * ∑ k ∈ Finset.range n, (54 : ℤ) ^ k = (54 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
