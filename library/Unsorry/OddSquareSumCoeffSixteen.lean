import Mathlib

/-- Goal `odd-square-sum-coeff-sixteen`: scaled odd-square-sum closed form, by induction on `n`. -/
theorem odd_square_sum_coeff_sixteen (n : ℕ) : 3 * ∑ k ∈ Finset.range n, 16 * (2 * (k : ℤ) + 1) ^ 2 = 16 * (n : ℤ) * (2 * (n : ℤ) - 1) * (2 * (n : ℤ) + 1) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
