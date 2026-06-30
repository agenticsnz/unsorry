import Mathlib

/-- Goal `alt-geometric-ratio-twentysix`: alternating geometric series (ratio -26) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_twentysix (n : ℕ) : ((26 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(26 : ℤ)) ^ k = 1 - (-(26 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
