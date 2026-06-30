import Mathlib

/-- Goal `alt-geometric-ratio-nine`: alternating geometric series (ratio -9) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_nine (n : ℕ) : ((9 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(9 : ℤ)) ^ k = 1 - (-(9 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
