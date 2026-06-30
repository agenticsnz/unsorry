import Mathlib

/-- Goal `alt-geometric-ratio-twentytwo`: alternating geometric series (ratio -22) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_twentytwo (n : ℕ) : ((22 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(22 : ℤ)) ^ k = 1 - (-(22 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
