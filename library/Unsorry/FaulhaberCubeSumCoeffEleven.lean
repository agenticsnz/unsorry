import Mathlib

/-- Goal `faulhaber-cube-sum-coeff-eleven`: a Faulhaber power sum (degree 3, coefficient 11) closed form, by induction on `n`. -/
theorem faulhaber_cube_sum_coeff_eleven (n : ℕ) : 44 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 3 = 11 * (((n : ℤ) * ((n : ℤ) - 1)) ^ 2) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
