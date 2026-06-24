import Mathlib

/-- Goal `faulhaber-square-sum-coeff-fiftynine`: a Faulhaber power sum (degree 2, coefficient 59) closed form, by induction on `n`. -/
theorem faulhaber_square_sum_coeff_fiftynine (n : ℕ) : 354 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 2 = 59 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1)) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
