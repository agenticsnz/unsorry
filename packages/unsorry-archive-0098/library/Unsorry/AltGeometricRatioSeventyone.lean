import Mathlib

/-- Goal `alt-geometric-ratio-seventyone`: alternating geometric series (ratio -71) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_seventyone (n : ℕ) : ((71 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(71 : ℤ)) ^ k = 1 - (-(71 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
