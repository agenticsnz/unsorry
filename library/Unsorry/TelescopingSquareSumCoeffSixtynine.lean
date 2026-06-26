import Mathlib

/-- Goal `telescoping-square-sum-coeff-sixtynine`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_sixtynine (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 69 * (k : ℤ) + 69) = 69 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
