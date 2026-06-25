import Mathlib

/-- Goal `alt-geometric-ratio-twentynine`: alternating geometric series (ratio -29) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_twentynine (n : ℕ) : ((29 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(29 : ℤ)) ^ k = 1 - (-(29 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
