import Mathlib

/-- Goal `alt-geometric-ratio-sixtythree`: alternating geometric series (ratio -63) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_sixtythree (n : ℕ) : ((63 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(63 : ℤ)) ^ k = 1 - (-(63 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
