import Mathlib

/-- Goal `alt-geometric-ratio-eleven`: alternating geometric series (ratio -11) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_eleven (n : ℕ) : ((11 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(11 : ℤ)) ^ k = 1 - (-(11 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
