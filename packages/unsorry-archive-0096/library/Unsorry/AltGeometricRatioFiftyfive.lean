import Mathlib

/-- Goal `alt-geometric-ratio-fiftyfive`: alternating geometric series (ratio -55) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fiftyfive (n : ℕ) : ((55 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(55 : ℤ)) ^ k = 1 - (-(55 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
