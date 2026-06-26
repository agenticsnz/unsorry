import Mathlib

/-- Goal `alt-geometric-ratio-seven`: alternating geometric series (ratio -7) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_seven (n : ℕ) : ((7 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(7 : ℤ)) ^ k = 1 - (-(7 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
