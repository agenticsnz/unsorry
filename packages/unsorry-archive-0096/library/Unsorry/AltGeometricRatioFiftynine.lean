import Mathlib

/-- Goal `alt-geometric-ratio-fiftynine`: alternating geometric series (ratio -59) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fiftynine (n : ℕ) : ((59 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(59 : ℤ)) ^ k = 1 - (-(59 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
