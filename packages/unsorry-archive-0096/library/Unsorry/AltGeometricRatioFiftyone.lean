import Mathlib

/-- Goal `alt-geometric-ratio-fiftyone`: alternating geometric series (ratio -51) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fiftyone (n : ℕ) : ((51 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(51 : ℤ)) ^ k = 1 - (-(51 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
