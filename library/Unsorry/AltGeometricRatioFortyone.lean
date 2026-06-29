import Mathlib

/-- Goal `alt-geometric-ratio-fortyone`: alternating geometric series (ratio -41) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fortyone (n : ℕ) : ((41 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(41 : ℤ)) ^ k = 1 - (-(41 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
