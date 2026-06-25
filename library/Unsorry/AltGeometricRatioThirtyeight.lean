import Mathlib

/-- Goal `alt-geometric-ratio-thirtyeight`: alternating geometric series (ratio -38) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_thirtyeight (n : ℕ) : ((38 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(38 : ℤ)) ^ k = 1 - (-(38 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
