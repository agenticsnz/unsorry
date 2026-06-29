import Mathlib

/-- Goal `alt-geometric-ratio-fiftythree`: alternating geometric series (ratio -53) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fiftythree (n : ℕ) : ((53 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(53 : ℤ)) ^ k = 1 - (-(53 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
