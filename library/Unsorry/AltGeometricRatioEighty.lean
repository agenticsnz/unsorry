import Mathlib

/-- Goal `alt-geometric-ratio-eighty`: alternating geometric series (ratio -80) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_eighty (n : ℕ) : ((80 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(80 : ℤ)) ^ k = 1 - (-(80 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
