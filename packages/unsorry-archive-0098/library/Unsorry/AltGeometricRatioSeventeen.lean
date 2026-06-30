import Mathlib

/-- Goal `alt-geometric-ratio-seventeen`: alternating geometric series (ratio -17) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_seventeen (n : ℕ) : ((17 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(17 : ℤ)) ^ k = 1 - (-(17 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
