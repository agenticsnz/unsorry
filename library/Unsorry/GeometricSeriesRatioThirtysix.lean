import Mathlib

/-- Goal `geometric-series-ratio-thirtysix`: a geometric series with ratio 36 closed form, by induction on `n`. -/
theorem geometric_series_ratio_thirtysix (n : ℕ) : ((36 : ℤ) - 1) * ∑ k ∈ Finset.range n, (36 : ℤ) ^ k = (36 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
