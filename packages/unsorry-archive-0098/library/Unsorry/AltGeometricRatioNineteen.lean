import Mathlib

/-- Goal `alt-geometric-ratio-nineteen`: alternating geometric series (ratio -19) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_nineteen (n : ℕ) : ((19 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(19 : ℤ)) ^ k = 1 - (-(19 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
