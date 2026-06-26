import Mathlib

/-- Goal `alt-geometric-ratio-seventynine`: alternating geometric series (ratio -79) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_seventynine (n : ℕ) : ((79 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(79 : ℤ)) ^ k = 1 - (-(79 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
