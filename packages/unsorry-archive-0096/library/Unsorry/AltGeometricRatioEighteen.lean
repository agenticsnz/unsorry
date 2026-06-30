import Mathlib

/-- Goal `alt-geometric-ratio-eighteen`: alternating geometric series (ratio -18) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_eighteen (n : ℕ) : ((18 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(18 : ℤ)) ^ k = 1 - (-(18 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
