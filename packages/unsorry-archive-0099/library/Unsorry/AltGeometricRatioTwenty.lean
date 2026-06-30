import Mathlib

/-- Goal `alt-geometric-ratio-twenty`: alternating geometric series (ratio -20) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_twenty (n : ℕ) : ((20 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(20 : ℤ)) ^ k = 1 - (-(20 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
