import Mathlib

/-- Goal `alt-geometric-ratio-sixtyseven`: alternating geometric series (ratio -67) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_sixtyseven (n : ℕ) : ((67 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(67 : ℤ)) ^ k = 1 - (-(67 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
