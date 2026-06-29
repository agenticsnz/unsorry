import Mathlib

/-- Goal `alt-geometric-ratio-thirty`: alternating geometric series (ratio -30) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_thirty (n : ℕ) : ((30 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(30 : ℤ)) ^ k = 1 - (-(30 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
