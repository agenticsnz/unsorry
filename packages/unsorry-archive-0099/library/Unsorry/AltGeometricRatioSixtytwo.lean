import Mathlib

/-- Goal `alt-geometric-ratio-sixtytwo`: alternating geometric series (ratio -62) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_sixtytwo (n : ℕ) : ((62 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(62 : ℤ)) ^ k = 1 - (-(62 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
