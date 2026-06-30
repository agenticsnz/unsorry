import Mathlib

/-- Goal `alt-geometric-ratio-sixtynine`: alternating geometric series (ratio -69) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_sixtynine (n : ℕ) : ((69 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(69 : ℤ)) ^ k = 1 - (-(69 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
