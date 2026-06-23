import Mathlib

/-- Goal `faulhaber-cube-sum-coeff-three`: a Faulhaber power sum (degree 3, coefficient 3) closed form, by induction on `n`. -/
theorem faulhaber_cube_sum_coeff_three (n : ℕ) : 12 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 3 = 3 * (((n : ℤ) * ((n : ℤ) - 1)) ^ 2) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
