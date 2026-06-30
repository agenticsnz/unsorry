import Mathlib

/-- Goal `alt-geometric-ratio-three`: alternating geometric series (ratio -3) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_three (n : ℕ) : ((3 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(3 : ℤ)) ^ k = 1 - (-(3 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
