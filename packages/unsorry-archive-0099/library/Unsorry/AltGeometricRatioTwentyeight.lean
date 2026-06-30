import Mathlib

/-- Goal `alt-geometric-ratio-twentyeight`: alternating geometric series (ratio -28) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_twentyeight (n : ℕ) : ((28 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(28 : ℤ)) ^ k = 1 - (-(28 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
