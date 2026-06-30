import Mathlib

/-- Goal `alt-geometric-ratio-fortyfive`: alternating geometric series (ratio -45) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fortyfive (n : ℕ) : ((45 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(45 : ℤ)) ^ k = 1 - (-(45 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
