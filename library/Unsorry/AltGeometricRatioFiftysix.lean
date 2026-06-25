import Mathlib

/-- Goal `alt-geometric-ratio-fiftysix`: alternating geometric series (ratio -56) closed form, by induction on `n`. -/
theorem alt_geometric_ratio_fiftysix (n : ℕ) : ((56 : ℤ) + 1) * ∑ k ∈ Finset.range n, (-(56 : ℤ)) ^ k = 1 - (-(56 : ℤ)) ^ n := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; ring
