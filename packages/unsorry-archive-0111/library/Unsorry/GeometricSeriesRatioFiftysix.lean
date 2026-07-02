import Mathlib

/-- Goal `geometric-series-ratio-fiftysix`: a geometric series with ratio 56 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fiftysix (n : ℕ) : ((56 : ℤ) - 1) * ∑ k ∈ Finset.range n, (56 : ℤ) ^ k = (56 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
