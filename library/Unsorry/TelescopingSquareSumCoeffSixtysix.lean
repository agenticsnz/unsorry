import Mathlib

/-- Goal `telescoping-square-sum-coeff-sixtysix`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_sixtysix (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 66 * (k : ℤ) + 66) = 66 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
