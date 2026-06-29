import Mathlib

/-- Goal `faulhaber-quintic-sum-coeff-fifty`: a Faulhaber power sum (degree 5, coefficient 50) closed form, by induction on `n`. -/
theorem faulhaber_quintic_sum_coeff_fifty (n : ℕ) : 600 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 50 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
