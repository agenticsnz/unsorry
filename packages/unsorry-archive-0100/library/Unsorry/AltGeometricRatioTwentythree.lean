import Mathlib

/-- Goal `alt-geometric-ratio-twentythree`: alternating geometric series (ratio -23) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_twentythree (n : ℕ) : ((23 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(23 : ℤ)) ^ k = 1 - (-(23 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
