import Mathlib

/-- Goal `alt-geometric-ratio-thirtytwo`: alternating geometric series (ratio -32) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_thirtytwo (n : ℕ) : ((32 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(32 : ℤ)) ^ k = 1 - (-(32 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
