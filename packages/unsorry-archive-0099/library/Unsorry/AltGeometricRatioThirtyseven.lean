import Mathlib

/-- Goal `alt-geometric-ratio-thirtyseven`: alternating geometric series (ratio -37) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_thirtyseven (n : ℕ) : ((37 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(37 : ℤ)) ^ k = 1 - (-(37 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
