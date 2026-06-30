import Mathlib

/-- Goal `alt-geometric-ratio-six`: alternating geometric series (ratio -6) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_six (n : ℕ) : ((6 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(6 : ℤ)) ^ k = 1 - (-(6 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
