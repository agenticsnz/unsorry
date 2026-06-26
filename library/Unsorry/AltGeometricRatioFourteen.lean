import Mathlib

/-- Goal `alt-geometric-ratio-fourteen`: alternating geometric series (ratio -14) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fourteen (n : ℕ) : ((14 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(14 : ℤ)) ^ k = 1 - (-(14 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
