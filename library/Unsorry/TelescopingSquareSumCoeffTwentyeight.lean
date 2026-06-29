import Mathlib

/-- Goal `telescoping-square-sum-coeff-twentyeight`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_twentyeight (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 28 * (k : ℤ) + 28) = 28 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
