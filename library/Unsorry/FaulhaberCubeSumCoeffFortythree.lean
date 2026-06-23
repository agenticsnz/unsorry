import Mathlib

/-- Goal `faulhaber-cube-sum-coeff-fortythree`: a Faulhaber power sum (degree 3, coefficient 43) closed form, by induction on `n`. -/
theorem faulhaber_cube_sum_coeff_fortythree (n : ℕ) : 172 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 3 = 43 * (((n : ℤ) * ((n : ℤ) - 1)) ^ 2) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
