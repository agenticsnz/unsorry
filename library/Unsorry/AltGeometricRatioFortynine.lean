import Mathlib

/-- Goal `alt-geometric-ratio-fortynine`: alternating geometric series (ratio -49) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fortynine (n : ℕ) : ((49 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(49 : ℤ)) ^ k = 1 - (-(49 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
