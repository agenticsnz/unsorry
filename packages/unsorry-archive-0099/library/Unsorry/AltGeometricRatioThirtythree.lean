import Mathlib

/-- Goal `alt-geometric-ratio-thirtythree`: alternating geometric series (ratio -33) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_thirtythree (n : ℕ) : ((33 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(33 : ℤ)) ^ k = 1 - (-(33 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
