import Mathlib

/-- Goal `faulhaber-square-sum-coeff-thirtysix`: a Faulhaber power sum (degree 2, coefficient 36) closed form, by induction on `n`. -/
theorem faulhaber_square_sum_coeff_thirtysix (n : ℕ) : 216 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 2 = 36 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1)) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
