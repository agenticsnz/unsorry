import Mathlib

/-- Goal `odd-square-sum-coeff-seventyfive`: scaled odd-square-sum closed form, by induction on `n`. -/
theorem odd_square_sum_coeff_seventyfive (n : ℕ) : 3 * ∑ k ∈ Finset.range n, 75 * (2 * (k : ℤ) + 1) ^ 2 = 75 * (n : ℤ) * (2 * (n : ℤ) - 1) * (2 * (n : ℤ) + 1) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
