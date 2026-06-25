import Mathlib

/-- Goal `alt-geometric-ratio-thirtynine`: alternating geometric series (ratio -39) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_thirtynine (n : ℕ) : ((39 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(39 : ℤ)) ^ k = 1 - (-(39 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
