import Mathlib

/-- Goal `alt-geometric-ratio-four`: alternating geometric series (ratio -4) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_four (n : ℕ) : ((4 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(4 : ℤ)) ^ k = 1 - (-(4 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
