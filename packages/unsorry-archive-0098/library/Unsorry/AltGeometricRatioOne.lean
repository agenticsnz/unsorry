import Mathlib

/-- Goal `alt-geometric-ratio-one`: alternating geometric series (ratio -1) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_one (n : ℕ) : ((1 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(1 : ℤ)) ^ k = 1 - (-(1 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
