import Mathlib

/-- Goal `alt-geometric-ratio-eight`: alternating geometric series (ratio -8) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_eight (n : ℕ) : ((8 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(8 : ℤ)) ^ k = 1 - (-(8 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
