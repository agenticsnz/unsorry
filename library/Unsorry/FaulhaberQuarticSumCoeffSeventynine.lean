import Mathlib

/-- Goal `faulhaber-quartic-sum-coeff-seventynine`: a Faulhaber power sum (degree 4, coefficient 79) closed form, by induction on `n`. -/
theorem faulhaber_quartic_sum_coeff_seventynine (n : ℕ) : 2370 * ∑ k ∈ Finset.range n, (k : ℤ) ^ 4 = 79 * ((n : ℤ) * ((n : ℤ) - 1) * (2 * (n : ℤ) - 1) * (3 * (n : ℤ) ^ 2 - 3 * (n : ℤ) - 1)) := by
  induction n with
  | zero => simp
  | succ m ih => rw [Finset.sum_range_succ, mul_add, ih]; push_cast; ring
