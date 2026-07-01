import Mathlib

/-- Goal `faulhaber-quartic-sum-coeff-fiftyseven`: a Faulhaber power sum (degree 4, coefficient 57) closed form, by induction on `n`. -/
theorem faulhaber_quartic_sum_coeff_fiftyseven (n : ℕ) : 1710 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 4 = 57 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) * (3 * (n : ℤ) ^ 2 - 3 * (n : ℤ) - 1)) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
