import Mathlib

/-- Goal `alt-geometric-ratio-fortyseven`: alternating geometric series (ratio -47) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fortyseven (n : ℕ) : ((47 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(47 : ℤ)) ^ k = 1 - (-(47 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
