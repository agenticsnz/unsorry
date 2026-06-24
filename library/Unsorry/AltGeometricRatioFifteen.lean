import Mathlib

/-- Goal `alt-geometric-ratio-fifteen`: alternating geometric series (ratio -15) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fifteen (n : ℕ) : ((15 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(15 : ℤ)) ^ k = 1 - (-(15 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
