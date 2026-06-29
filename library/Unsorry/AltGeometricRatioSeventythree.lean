import Mathlib

/-- Goal `alt-geometric-ratio-seventythree`: alternating geometric series (ratio -73) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_seventythree (n : ℕ) : ((73 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(73 : ℤ)) ^ k = 1 - (-(73 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
