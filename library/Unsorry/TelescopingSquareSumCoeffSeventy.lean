import Mathlib

/-- Goal `telescoping-square-sum-coeff-seventy`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_seventy (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 70 * (k : ℤ) + 70) = 70 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
