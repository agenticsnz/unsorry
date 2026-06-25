import Mathlib

/-- Goal `alt-geometric-ratio-twentyseven`: alternating geometric series (ratio -27) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_twentyseven (n : ℕ) : ((27 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(27 : ℤ)) ^ k = 1 - (-(27 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
