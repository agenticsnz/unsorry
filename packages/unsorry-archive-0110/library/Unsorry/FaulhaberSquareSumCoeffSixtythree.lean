import Mathlib

/-- Goal `faulhaber-square-sum-coeff-sixtythree`: a Faulhaber power sum (degree 2, coefficient 63) closed form, by induction on `n`. -/
theorem faulhaber_square_sum_coeff_sixtythree (n : ℕ) : 378 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 2 = 63 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1)) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
