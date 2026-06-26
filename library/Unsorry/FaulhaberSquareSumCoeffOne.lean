import Mathlib

/-- Goal `faulhaber-square-sum-coeff-one`: a Faulhaber power sum (degree 2, coefficient 1) closed form, by induction on `n`. -/
theorem faulhaber_square_sum_coeff_one (n : ℕ) : 6 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 2 = 1 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1)) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
