import Mathlib

/-- Goal `alt-geometric-ratio-thirtyone`: alternating geometric series (ratio -31) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_thirtyone (n : ℕ) : ((31 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(31 : ℤ)) ^ k = 1 - (-(31 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
