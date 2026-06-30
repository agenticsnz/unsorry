import Mathlib

/-- Goal `alt-geometric-ratio-seventy`: alternating geometric series (ratio -70) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_seventy (n : ℕ) : ((70 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(70 : ℤ)) ^ k = 1 - (-(70 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
