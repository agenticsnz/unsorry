import Mathlib

/-- Goal `alt-geometric-ratio-sixteen`: alternating geometric series (ratio -16) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_sixteen (n : ℕ) : ((16 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(16 : ℤ)) ^ k = 1 - (-(16 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
