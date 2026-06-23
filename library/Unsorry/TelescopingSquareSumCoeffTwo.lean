import Mathlib

/-- Goal `telescoping-square-sum-coeff-two`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_two (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 2 * (k : ℤ) + 2) = 2 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
