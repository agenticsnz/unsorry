import Mathlib

/-- Goal `alt-geometric-ratio-fiftyseven`: alternating geometric series (ratio -57) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fiftyseven (n : ℕ) : ((57 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(57 : ℤ)) ^ k = 1 - (-(57 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
