import Mathlib

/-- Goal `telescoping-square-sum-coeff-sixtythree`: telescoping power-sum closed form, by induction on `n`. -/
theorem telescoping_square_sum_coeff_sixtythree (n : ℕ) : ∑ k ∈ Finset.range n, (2 * 63 * (k : ℤ) + 63) = 63 * (n : ℤ) ^ 2 := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, ih]; push_cast; ring
