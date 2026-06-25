import Mathlib

/-- Goal `alt-geometric-ratio-sixty`: alternating geometric series (ratio -60) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_sixty (n : ℕ) : ((60 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(60 : ℤ)) ^ k = 1 - (-(60 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
