import Mathlib

/-- Goal `alt-geometric-ratio-fortyfour`: alternating geometric series (ratio -44) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fortyfour (n : ℕ) : ((44 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(44 : ℤ)) ^ k = 1 - (-(44 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
