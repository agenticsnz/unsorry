import Mathlib

/-- Goal `alt-geometric-ratio-thirteen`: alternating geometric series (ratio -13) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_thirteen (n : ℕ) : ((13 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(13 : ℤ)) ^ k = 1 - (-(13 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
