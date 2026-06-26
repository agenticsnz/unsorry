import Mathlib

/-- Goal `alt-geometric-ratio-fortyeight`: alternating geometric series (ratio -48) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fortyeight (n : ℕ) : ((48 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(48 : ℤ)) ^ k = 1 - (-(48 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
