import Mathlib

/-- Goal `alt-geometric-ratio-twentyfour`: alternating geometric series (ratio -24) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_twentyfour (n : ℕ) : ((24 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(24 : ℤ)) ^ k = 1 - (-(24 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
