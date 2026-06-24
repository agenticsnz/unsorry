import Mathlib

/-- Goal `alt-geometric-ratio-twentyfive`: alternating geometric series (ratio -25) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_twentyfive (n : ℕ) : ((25 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(25 : ℤ)) ^ k = 1 - (-(25 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
