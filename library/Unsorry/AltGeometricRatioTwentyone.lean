import Mathlib

/-- Goal `alt-geometric-ratio-twentyone`: alternating geometric series (ratio -21) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_twentyone (n : ℕ) : ((21 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(21 : ℤ)) ^ k = 1 - (-(21 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
