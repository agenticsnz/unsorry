import Mathlib

/-- Goal `alt-geometric-ratio-sixtysix`: alternating geometric series (ratio -66) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_sixtysix (n : ℕ) : ((66 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(66 : ℤ)) ^ k = 1 - (-(66 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
