import Mathlib

/-- Goal `telescoping-square-sum-coeff-five`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_five (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 5 * (k : ℤ) + 5) = 5 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
