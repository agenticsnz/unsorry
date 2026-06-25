import Mathlib

/-- Goal `faulhaber-cube-sum-coeff-seventytwo`: a Faulhaber power sum (degree 3, coefficient 72) closed form, by induction on `n`. -/
theorem faulhaber_cube_sum_coeff_seventytwo (n : ℕ) : 288 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 3 = 72 * (((n : ℤ) * ((n : ℤ) - 1)) ^ 2) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
