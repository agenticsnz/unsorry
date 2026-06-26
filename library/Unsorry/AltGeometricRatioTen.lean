import Mathlib

/-- Goal `alt-geometric-ratio-ten`: alternating geometric series (ratio -10) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_ten (n : ℕ) : ((10 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(10 : ℤ)) ^ k = 1 - (-(10 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
