import Mathlib

/-- Goal `alt-geometric-ratio-thirtyfour`: alternating geometric series (ratio -34) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_thirtyfour (n : ℕ) : ((34 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(34 : ℤ)) ^ k = 1 - (-(34 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
