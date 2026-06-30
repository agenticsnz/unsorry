import Mathlib

/-- Goal `alt-geometric-ratio-thirtyfive`: alternating geometric series (ratio -35) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_thirtyfive (n : ℕ) : ((35 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(35 : ℤ)) ^ k = 1 - (-(35 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
