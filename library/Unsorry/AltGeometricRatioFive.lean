import Mathlib

/-- Goal `alt-geometric-ratio-five`: alternating geometric series (ratio -5) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_five (n : ℕ) : ((5 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(5 : ℤ)) ^ k = 1 - (-(5 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
