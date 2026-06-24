import Mathlib

/-- Goal `alt-geometric-ratio-fiftyfour`: alternating geometric series (ratio -54) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fiftyfour (n : ℕ) : ((54 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(54 : ℤ)) ^ k = 1 - (-(54 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
