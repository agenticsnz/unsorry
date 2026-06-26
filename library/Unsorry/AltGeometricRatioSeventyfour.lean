import Mathlib

/-- Goal `alt-geometric-ratio-seventyfour`: alternating geometric series (ratio -74) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_seventyfour (n : ℕ) : ((74 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(74 : ℤ)) ^ k = 1 - (-(74 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
