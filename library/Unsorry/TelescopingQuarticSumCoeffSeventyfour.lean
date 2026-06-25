import Mathlib

/-- Goal `telescoping-quartic-sum-coeff-seventyfour`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_quartic_sum_coeff_seventyfour (n : ℕ) : ∑ k ∈ Finset.range n, (74 * (4 * (k : ℤ) ^ 3 + 6 * (k : ℤ) ^ 2 + 4 * (k : ℤ) + 1)) = 74 * (n : ℤ) ^ 4 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
