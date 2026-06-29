import Mathlib

/-- Goal `geometric-series-ratio-fortynine`: a geometric series with ratio 49 closed form, by induction on `n`. -/
theorem geometric_series_ratio_fortynine (n : ℕ) : ((49 : ℤ) - 1) * ∑ k ∈ Finset.range n, (49 : ℤ) ^ k = (49 : ℤ) ^ n - 1 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
