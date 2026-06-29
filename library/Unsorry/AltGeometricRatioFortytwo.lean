import Mathlib

/-- Goal `alt-geometric-ratio-fortytwo`: alternating geometric series (ratio -42) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fortytwo (n : ℕ) : ((42 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(42 : ℤ)) ^ k = 1 - (-(42 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
