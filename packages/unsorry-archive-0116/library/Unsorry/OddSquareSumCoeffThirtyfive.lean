import Mathlib

/-- Goal `odd-square-sum-coeff-thirtyfive`: scaled odd-square-sum closed form, by induction on `n`. -/
theorem odd_square_sum_coeff_thirtyfive (n : ℕ) : 3 * ∑ k ∈ Finset.range n, 35 * (2 * (k : ℤ) + 1) ^ 2 = 35 * (n : ℤ) * (2 * (n : ℤ) - 1) * (2 * (n : ℤ) + 1) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
