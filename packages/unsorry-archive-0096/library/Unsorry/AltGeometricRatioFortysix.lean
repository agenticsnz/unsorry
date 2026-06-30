import Mathlib

/-- Goal `alt-geometric-ratio-fortysix`: alternating geometric series (ratio -46) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fortysix (n : ℕ) : ((46 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(46 : ℤ)) ^ k = 1 - (-(46 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
