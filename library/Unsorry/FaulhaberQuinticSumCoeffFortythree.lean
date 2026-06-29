import Mathlib

/-- Goal `faulhaber-quintic-sum-coeff-fortythree`: a Faulhaber power sum (degree 5, coefficient 43) closed form, by induction on `n`. -/
theorem faulhaber_quintic_sum_coeff_fortythree (n : ℕ) : 516 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 43 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
