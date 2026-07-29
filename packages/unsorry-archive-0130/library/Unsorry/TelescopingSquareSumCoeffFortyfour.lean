import Mathlib

/-- Goal `telescoping-square-sum-coeff-fortyfour`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_fortyfour (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 44 * (k : ℤ) + 44) = 44 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
