import Mathlib

/-- Goal `faulhaber-quintic-sum-coeff-twentyone`: a Faulhaber power sum (degree 5, coefficient 21) closed form, by induction on `n`. -/
theorem faulhaber_quintic_sum_coeff_twentyone (n : ℕ) : 252 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 5 = 21 * ((n : ℤ) ^ 2 * ((n : ℤ) - 1) ^ 2 * (2 * (n : ℤ) ^ 2 - 2 * (n : ℤ) - 1)) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
