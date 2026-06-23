import Mathlib

/-- Goal `alt-geometric-ratio-seventysix`: alternating geometric series (ratio -76) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_seventysix (n : ℕ) : ((76 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(76 : ℤ)) ^ k = 1 - (-(76 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
