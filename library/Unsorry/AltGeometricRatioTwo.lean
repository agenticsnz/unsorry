import Mathlib

/-- Goal `alt-geometric-ratio-two`: alternating geometric series (ratio -2) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_two (n : ℕ) : ((2 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(2 : ℤ)) ^ k = 1 - (-(2 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
