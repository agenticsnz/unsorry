import Mathlib

/-- Goal `alt-geometric-ratio-fiftyeight`: alternating geometric series (ratio -58) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fiftyeight (n : ℕ) : ((58 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(58 : ℤ)) ^ k = 1 - (-(58 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
