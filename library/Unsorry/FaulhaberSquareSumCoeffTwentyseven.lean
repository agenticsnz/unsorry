import Mathlib

/-- Goal `faulhaber-square-sum-coeff-twentyseven`: a Faulhaber power sum (degree 2, coefficient 27) closed form, by induction on `n`. -/
theorem faulhaber_square_sum_coeff_twentyseven (n : ℕ) : 162 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 2 = 27 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1)) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
