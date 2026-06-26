import Mathlib

/-- Goal `telescoping-square-sum-coeff-thirty`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_thirty (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 30 * (k : ℤ) + 30) = 30 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
