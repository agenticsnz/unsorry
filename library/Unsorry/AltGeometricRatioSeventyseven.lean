import Mathlib

/-- Goal `alt-geometric-ratio-seventyseven`: alternating geometric series (ratio -77) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_seventyseven (n : ℕ) : ((77 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(77 : ℤ)) ^ k = 1 - (-(77 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
