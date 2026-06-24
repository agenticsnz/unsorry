import Mathlib

/-- Goal `alt-geometric-ratio-forty`: alternating geometric series (ratio -40) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_forty (n : ℕ) : ((40 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(40 : ℤ)) ^ k = 1 - (-(40 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
