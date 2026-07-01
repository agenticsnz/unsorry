import Mathlib

/-- Goal `faulhaber-quartic-sum-coeff-eleven`: a Faulhaber power sum (degree 4, coefficient 11) closed form, by induction on `n`. -/
theorem faulhaber_quartic_sum_coeff_eleven (n : ℕ) : 330 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 4 = 11 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) * (3 * (n : ℤ) ^ 2 - 3 * (n : ℤ) - 1)) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
