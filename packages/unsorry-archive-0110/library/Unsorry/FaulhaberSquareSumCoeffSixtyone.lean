import Mathlib

/-- Goal `faulhaber-square-sum-coeff-sixtyone`: a Faulhaber power sum (degree 2, coefficient 61) closed form, by induction on `n`. -/
theorem faulhaber_square_sum_coeff_sixtyone (n : ℕ) : 366 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 2 = 61 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1)) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
