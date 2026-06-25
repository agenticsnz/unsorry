import Mathlib

/-- Goal `alt-geometric-ratio-twelve`: alternating geometric series (ratio -12) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_twelve (n : ℕ) : ((12 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(12 : ℤ)) ^ k = 1 - (-(12 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
