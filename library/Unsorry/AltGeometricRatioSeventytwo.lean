import Mathlib

/-- Goal `alt-geometric-ratio-seventytwo`: alternating geometric series (ratio -72) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_seventytwo (n : ℕ) : ((72 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(72 : ℤ)) ^ k = 1 - (-(72 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
