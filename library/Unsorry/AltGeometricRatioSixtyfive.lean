import Mathlib

/-- Goal `alt-geometric-ratio-sixtyfive`: alternating geometric series (ratio -65) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_sixtyfive (n : ℕ) : ((65 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(65 : ℤ)) ^ k = 1 - (-(65 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
