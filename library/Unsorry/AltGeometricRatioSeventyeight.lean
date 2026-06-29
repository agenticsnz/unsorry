import Mathlib

/-- Goal `alt-geometric-ratio-seventyeight`: alternating geometric series (ratio -78) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_seventyeight (n : ℕ) : ((78 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(78 : ℤ)) ^ k = 1 - (-(78 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
