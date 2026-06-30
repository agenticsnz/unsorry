import Mathlib

/-- Goal `alt-geometric-ratio-fifty`: alternating geometric series (ratio -50) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fifty (n : ℕ) : ((50 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(50 : ℤ)) ^ k = 1 - (-(50 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
