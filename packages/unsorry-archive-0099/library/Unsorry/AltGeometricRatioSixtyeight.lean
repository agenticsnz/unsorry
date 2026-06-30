import Mathlib

/-- Goal `alt-geometric-ratio-sixtyeight`: alternating geometric series (ratio -68) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_sixtyeight (n : ℕ) : ((68 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(68 : ℤ)) ^ k = 1 - (-(68 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
