import Mathlib

/-- Goal `alt-geometric-ratio-seventyfive`: alternating geometric series (ratio -75) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_seventyfive (n : ℕ) : ((75 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(75 : ℤ)) ^ k = 1 - (-(75 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
