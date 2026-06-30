import Mathlib

/-- Goal `alt-geometric-ratio-fortythree`: alternating geometric series (ratio -43) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fortythree (n : ℕ) : ((43 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(43 : ℤ)) ^ k = 1 - (-(43 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
